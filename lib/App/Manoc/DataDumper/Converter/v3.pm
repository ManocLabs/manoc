package    # hide from CPAN
    App::Manoc::DataDumper::Converter::v3;
use Moose;

##VERSION

extends 'App::Manoc::DataDumper::Converter::Base';

use App::Manoc::Utils::IPAddress qw(padded_ipaddr netmask2prefix);

has 'device_id_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_device_id_map',
);

has 'device_id_counter' => (
    isa     => 'Int',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_device_id_counter',
);

has 'interface_id_counter' => (
    isa     => 'Int',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_device_id_counter',
);

has 'interface_id_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_interface_id_map',
);

has 'hwasset_id_counter' => (
    isa     => 'Int',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_hwasset_id_counter',
);

has 'device_hwasset_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
);

has 'device_credentials_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
);

has 'device_credentials_id_counter' => (
    isa     => 'Int',
    is      => 'rw',
    default => 1
);

has 'dhcp_server_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
);

has 'dhcp_server_id_counter' => (
    isa     => 'Int',
    is      => 'rw',
    default => 1
);

has 'network_id_counter' => (
    isa => 'Int',
    is  => 'rw'
);

has 'default_lan_segment' => (
    isa     => 'Object',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_default_lan_segment',
);

sub _build_device_id_map {
    my $self = shift;
    $self->log->info("Loading device ids from DB");

    my @devices = $self->schema->resultset('Device')->search(
        undef,
        {
            columns => [qw/ id mng_address /]
        }
    );

    unless (@devices) {
        $self->log->logdie("No devices found while loading address->id map");
    }

    my %id_map = map { $_->mng_address->padded => $_->id } @devices;
    $self->log->info("Loaded idmap (@devices)");
    return \%id_map;
}

sub _build_interface_id_map {
    my $self = shift;
    $self->log->info("Loading interface ids from DB");

    my @ifaces = $self->schema->resultset('DeviceIface')->search(
        undef,
        {
            columns => [qw/ id  device_id name /]
        }
    );

    my %id_map = map { $_->device_id . ":" . $_->name => $_->id } @ifaces;

    $self->log->info("Loaded idmap ifaces");
    return \%id_map;
}

sub _build_device_id_counter {
    my $self = shift;

    my $id = $self->schema->resultset('Device')->search( {} )->get_column('id')->max();

    return defined($id) ? $id + 1 : 1;
}

sub _build_interface_id_counter {
    my $self = shift;

    my $id = $self->schema->resultset('DeviceIface')->search( {} )->get_column('id')->max();

    return defined($id) ? $id + 1 : 1;
}

sub _build_hwasset_id_counter {
    my $self = shift;

    my $id = $self->schema->resultset('HWAsset')->search( {} )->get_column('id')->max();

    return defined($id) ? $id + 1 : 1;
}

# use $self->device_id_map to rewrite an ip-based device foreign key
sub _rewrite_device_id {
    my ( $self, $data, $column_name, $new_column_name ) = @_;
    my $map = $self->device_id_map;

    $new_column_name ||= $column_name;

    my @new_data;
    foreach (@$data) {
        my $old_id = padded_ipaddr( $_->{$column_name} );
        my $new_id = $map->{$old_id};
        if ( !defined($new_id) ) {
            $self->log->error("No id found in map for device $old_id");
            next;
        }
        $_->{$new_column_name} = $new_id;
        delete $_->{$column_name} if $new_column_name ne $column_name;
        push @new_data, $_;
    }

    @$data = @new_data;
}

sub _build_default_lan_segment {
    my $self = shift;

    my $rs      = $self->schema->resultset('LanSegment');
    my $segment = $rs->find_or_create(
        {
            name => 'default',
        }
    );

    return $segment;
}

sub default_lan_segment_id {
    shift->default_lan_segment->id;
}

########################################################################

sub upgrade_cdp_neigh {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'from_device' => 'from_device_id' );
}

sub upgrade_Device {
    my ( $self, $data ) = @_;

    my %device_id_map = ();
    my $id            = $self->device_id_counter;

    foreach (@$data) {
        my $addr   = $_->{id};
        my $dev_id = $id++;
        $_->{mng_address}     = $addr;
        $_->{id}              = $dev_id;
        $device_id_map{$addr} = $dev_id;

        $_->{hwasset_id} = $self->device_hwasset_map->{$addr};

        # we have changed foreign key name
        $_->{rack_id}           = $_->{rack};
        $_->{mng_url_format_id} = $_->{mng_url_format};

        # cleanup attributes moved to hwasset and nwinfo
        delete @$_{
            qw(backup_enable
                get_arp get_mat get_dot11
                mat_native_vlan  vlan_arpinfo
                telnet_pwd enable_pwd
                snmp_com snmp_user
                snmp_password snmp_ver
                last_visited offline

                rack level
                os os_ver boottime vtp_domain
                vendor model serial
                mng_url_format
            )
        };
    }

    $self->device_id_counter($id);
    $self->device_id_map( \%device_id_map );
}

sub get_table_name_Credentials { 'devices' }

# NOTE: devices should fill a block
sub upgrade_Credentials {
    my ( $self, $data ) = @_;

    my @new_data;

    my $credentials_map = $self->device_credentials_map;
    my $id_counter      = $self->device_credentials_id_counter;

    # create a default set
    push @new_data,
        {
        id              => $id_counter++,
        name            => 'Default credentials',
        username        => undef,
        password        => undef,
        become_password => undef,
        snmp_community  => 'public',
        snmp_user       => undef,
        snmp_password   => undef,
        snmp_version    => 2,
        };

    foreach (@$data) {
        my $r = {};

        $r->{username}        = '';
        $r->{password}        = $_->{telnet_pwd};
        $r->{become_password} = $_->{enable_pwd};
        $r->{snmp_community}  = $_->{snmp_com};
        $r->{snmp_user}       = $_->{snmp_user};
        $r->{snmp_password}   = $_->{snmp_password};
        $r->{snmp_version}    = $_->{snmp_ver};

        my $credentials_id;

        # search if there is already a compatible credentials row
        # NOTE: this is not an optimal solution since there is no order in the input
        # it is just an heuristic

        foreach my $cred (@new_data) {

            # check if entries in $r have no mismatch,
            #e.g. all entries defined in $r have the same value
            my $mismatch = 0;
            while ( my ( $k, $v ) = each(%$r) ) {
                next unless defined($v);
                next if defined( $cred->{$k} ) && $v eq $cred->{$k};

                # mismatch found
                $mismatch = 1;
                last;
            }
            next if $mismatch;

            $credentials_id = $cred->{id};
        }

        if ( !defined($credentials_id) ) {
            $credentials_id = $id_counter++;
            $r->{id}        = $credentials_id;
            $r->{name}      = "Credentials $credentials_id";
            push @new_data, $r;
        }

        $credentials_map->{ $_->{id} } = $credentials_id;
    }

    $self->device_credentials_map($credentials_map);
    $self->device_credentials_id_counter($id_counter);

    @$data = @new_data;
}

sub get_table_name_DeviceNWInfo { 'devices' }

sub upgrade_DeviceNWInfo {
    my ( $self, $data ) = @_;
    my @new_data;

    my $credentials_map = $self->device_credentials_map;

    foreach (@$data) {
        my $r = {};

        my $device_id = $_->{id};

        $r->{get_config}         = $_->{backup_enable};
        $r->{get_arp}            = $_->{get_arp};
        $r->{get_mat}            = $_->{get_mat};
        $r->{get_dot11}          = $_->{get_dot11};
        $r->{mat_native_vlan_id} = $_->{mat_native_vlan};
        $r->{arp_vlan_id}        = $_->{vlan_arpinfo};

        $r->{credentials_id} = $credentials_map->{$device_id};

        $r->{model}      = $_->{model};
        $r->{serial}     = $_->{serial};
        $r->{os}         = $_->{os};
        $r->{os_ver}     = $_->{os_ver};
        $r->{vtp_domain} = $_->{vtp_domain};

        $r->{device}   = $device_id;
        $r->{manifold} = 'SNMP::Info';

        push @new_data, $r;
    }

    @$data = @new_data;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub upgrade_device_config {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );

    foreach (@$data) {
        delete $_->{last_visited};
    }
}

sub get_table_name_DHCPServer { [ 'dhcp_lease', 'dhcp_reservation' ] }

sub upgrade_DHCPServer {
    my ( $self, $data ) = @_;

    # maps name to id
    my $dhcp_server_map = $self->dhcp_server_map;
    my $id              = $self->dhcp_server_id_counter;

    my @servers;

    foreach (@$data) {
        my $server = $_->{server};
        next if $dhcp_server_map->{$server};

        my $server_id = $id++;

        $self->log->info("Defined DHCP server $server (id=$server_id)");

        my $r = {
            id   => $server_id,
            name => $server,
        };
        push @servers, $r;

        $dhcp_server_map->{$server} = $server_id;
    }

    $self->dhcp_server_id_counter($id);
    $self->dhcp_server_map($dhcp_server_map);
    @$data = @servers;
}

sub upgrade_DHCPLease {
    my ( $self, $data ) = @_;

    my $dhcp_server_map = $self->dhcp_server_map();

    foreach (@$data) {
        my $server_id = $dhcp_server_map->{ $_->{server} };
        delete $_->{server};
        $_->{dhcp_server_id} = $server_id;
    }
}

sub upgrade_DHCPReservation {
    my ( $self, $data ) = @_;

    my $dhcp_server_map = $self->dhcp_server_map();

    foreach (@$data) {
        my $server_id = $dhcp_server_map->{ $_->{server} };
        delete $_->{server};
        $_->{dhcp_server_id} = $server_id;
    }
}

sub upgrade_dot11_assoc {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub upgrade_dot11client {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub get_table_name_HWAsset { 'devices' }

sub upgrade_HWAsset {
    my ( $self, $data ) = @_;

    my @new_data;

    my %device_hwasset_map = ();

    my $id       = $self->hwasset_id_counter;
    my $type     = App::Manoc::DB::Result::HWAsset->TYPE_DEVICE;
    my $location = App::Manoc::DB::Result::HWAsset->LOCATION_RACK;

    foreach (@$data) {
        my $addr     = $_->{id};
        my $asset_id = $id++;

        my $r = {};
        $r->{id}         = $asset_id;
        $r->{model}      = $_->{model}  || 'Unknown';
        $r->{vendor}     = $_->{vendor} || 'Unknown';
        $r->{serial}     = $_->{serial};
        $r->{rack_id}    = $_->{rack};
        $r->{rack_level} = $_->{level};
        $r->{type}       = $type;
        $r->{location}   = $location;

        $r->{inventory} = sprintf( "%s%06d", $type, $asset_id );

        $device_hwasset_map{$addr} = $asset_id;

        push @new_data, $r;
    }

    $self->hwasset_id_counter($id);
    $self->device_hwasset_map( \%device_hwasset_map );
    @$data = @new_data;
}

sub after_import_HWAsset {
    my ( $self, $source ) = @_;

    my $rs = $source->resultset->search();
    while ( my $asset = $rs->next ) {
        if ( my $rack = $asset->rack ) {
            $asset->building( $rack->building );
            $asset->floor( $rack->floor );
            $asset->room( $rack->room );
            $asset->update();
        }
    }
}

sub upgrade_if_notes {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub upgrade_if_status {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub get_table_name_DeviceIface { 'if_status' }

sub get_additional_table_name_DeviceIface { 'if_notes' }

sub upgrade_DeviceIface {
    my ( $self, $data ) = @_;
    my @new_data;

    my $id_map = $self->interface_id_map;
    my $id     = $self->interface_id_counter;

    foreach (@$data) {
        my $r = {};

        my $iface_id  = $id++;
        my $name      = $_->{interface};
        my $device_id = $_->{device_id};

        $r->{id}        = $iface_id;
        $r->{name}      = $name;
        $r->{device_id} = $device_id;
        $r->{routed}    = 0;

        # old manoc all interfaces generated by nw
        $r->{autocreated}  = 1;
        $r->{nw_confirmed} = 1;

        # use name in lower case for idmap
        $id_map->{ "${device_id}:" . lc($name) } = $iface_id;
        push @new_data, $r;
    }

    @$data = @new_data;

    $self->interface_id_counter($id);
}

sub process_additional_table_DeviceIface_if_notes {
    my ( $self, $data ) = @_;
    my @new_data;

    my $id_map = $self->interface_id_map;
    use Data::Dumper;
    print STDERR Dumper($id_map);

ROW:
    foreach (@$data) {
        # use name in lower case for idmap
        my $name      = lc( $_->{interface} );
        my $device_id = $_->{device_id};

        my $iface_id = $id_map->{"${device_id}:${name}"};
        if ( !defined($iface_id) ) {
            $self->log->info("Skipping notes for interface  ${device_id}:${name}");
            next ROW;
        }

        my $r = {};

        $r->{id}    = $iface_id;
        $r->{notes} = $_->{notes};

        push @new_data, $r;

    }

    @$data = @new_data;

}

sub get_table_name_DeviceIfStatus { 'if_status' }

sub upgrade_DeviceIfStatus {
    my ( $self, $data ) = @_;

    my $id_map = $self->interface_id_map;

    foreach (@$data) {
        my $device_id = $_->{device_id};
        # use name in lower case for idmap
        my $name     = lc( $_->{interface} );
        my $iface_id = $id_map->{"${device_id}:${name}"};

        $_->{interface_id} = $iface_id;

        # cleanup attributes
        delete @$_{qw(device_id interface )};
    }
}

sub get_table_name_IPAddressInfo { 'ip' }

sub upgrade_mat {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device', 'device_id' );
}

sub upgrade_racks {
    my ( $self, $data ) = @_;

    foreach (@$data) {
        $_->{room}        = '';
        $_->{building_id} = $_->{building};
        delete $_->{building};
    }
}

# delete session datas
sub upgrade_sessions {
    my ( $self, $data ) = @_;
    @$data = ();
}

sub upgrade_ssid_list {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub upgrade_uplinks {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub upgrade_users {
    my ( $self, $data ) = @_;

    foreach (@$data) {
        $_->{username} = $_->{login};
        delete $_->{login};

        $_->{superadmin} = $_->{username} eq 'admin' ? 1 : 0;
    }
}

sub upgrade_Vlan {
    my ( $self, $data ) = @_;
    my $segment_id = $self->default_lan_segment_id;

    foreach (@$data) {
        $_->{vlan_range_id} = $_->{vlan_range};
        delete $_->{vlan_range};

        $_->{lan_segment_id} = $segment_id;
        $_->{vid}            = $_->{id};
    }
}

sub upgrade_VlanVtp {
    my ( $self, $data ) = @_;
    my $segment_name = $self->default_lan_segment->name;

    foreach (@$data) {
        $_->{vid}        = $_->{id};
        $_->{vtp_domain} = $segment_name;
    }
}

sub upgrade_VlanRange {
    my ( $self, $data ) = @_;

    my $segment_id = $self->default_lan_segment_id;

    foreach (@$data) {
        $_->{lan_segment_id} = $segment_id;
    }
}

sub get_table_name_IPNetwork { 'ip_range' }

sub upgrade_IPNetwork {
    my ( $self, $data ) = @_;

    @$data = grep { $_->{network} } @$data;

    foreach (@$data) {
        $_->{address}   = $_->{network};
        $_->{prefix}    = netmask2prefix( $_->{netmask} );
        $_->{broadcast} = $_->{to_addr};
        delete @$_{qw(from_addr to_addr network netmask parent)};
    }
}

sub after_import_IPNetwork {
    my ( $self, $source ) = @_;

    $self->log->info("Rebuilding IPNetwork tree");
    $source->resultset->rebuild_tree();
}

sub get_table_name_IPBlock { 'ip_range' }

sub upgrade_IPBlock {
    my ( $self, $data ) = @_;

    my $id = $self->network_id_counter;
    @$data = grep { !$_->{network} } @$data;

    foreach (@$data) {
        $_->{id} = $id++;
        delete @$_{qw(network netmask vlan_id parent)};
    }

    $self->network_id_counter($id);
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
