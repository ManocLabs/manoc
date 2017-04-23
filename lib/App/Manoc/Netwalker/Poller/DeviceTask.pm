package App::Manoc::Netwalker::Poller::DeviceTask;
#ABSTRACT: Device poller task

use Moose;

##VERSION

use Try::Tiny;

use App::Manoc::Netwalker::Poller::TaskReport;
use App::Manoc::Manifold;
use App::Manoc::IPAddress::IPv4;

=attr device_id

The id in Manoc DB of the device to update.

=cut

has 'device_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

=attr device_entry

The Device row in Manoc DB identified by C<device_id>.

=cut

has 'device_entry' => (
    is      => 'ro',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    builder => '_build_device_entry',
);

=attr nwinfo

NWInfo associated to the current C<device_entry>.

=cut

has 'nwinfo' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => '_build_nwinfo',
);

=attr device_set

A set (hash) of all mng_address known to Manoc used to to discover
 neighbors and uplinks.

=cut

has 'device_set' => (
    is      => 'ro',
    isa     => 'HashRef',
    builder => '_build_device_set',
);

=attr source

The source for information about the device: a connected Manifold object.

=cut

has 'source' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_source',
);

=attr config_source

The Manifold to use as a source for device configuration backup.

=cut

has 'config_source' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_config_source',
);

=attr task_report

=cut

has 'task_report' => (
    is       => 'ro',
    required => 0,
    builder  => '_build_task_report',
);

=attr uplinks

=cut

has 'uplinks' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uplinks',
);

=attr native_vlan

=cut

has 'native_vlan' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_native_vlan',
);

=attr arp_vlan

=cut

has 'arp_vlan' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_arp_vlan',
);

with 'App::Manoc::Netwalker::Poller::BaseTask', 'App::Manoc::Logger::Role';

#----------------------------------------------------------------------#
#                                                                      #
#              A t t r i b u t e s   B u i l d e r                     #
#                                                                      #
#----------------------------------------------------------------------#

sub _build_arp_vlan {
    my $self = shift;

    my $vlan = $self->nwinfo->arp_vlan->vid ||
        $self->config->default_vlan;
    return defined($vlan) ? $vlan : 1;
}

sub _build_device_entry {
    my $self      = shift;
    my $device_id = $self->device_id;

    return $self->schema->resultset('Device')->find( $self->device_id );
}

sub _build_device_set {
    my $self = shift;

    # columns are not inflated
    my @addresses = $self->schema->resultset('Device')->get_column('mng_address')->all;
    my %addr_set = map { App::Manoc::IPAddress::IPv4->new($_)->unpadded => 1 } @addresses;
    return \%addr_set;
}

sub _build_native_vlan {
    my $self = shift;

    my $vlan = $self->nwinfo->mat_native_vlan->id ||
        $self->config->default_vlan;
    return defined($vlan) ? $vlan : 1;
}

sub _build_nwinfo {
    my $self = shift;

    return $self->device_entry->netwalker_info;
}

sub _create_manifold {
    my $self          = shift;
    my $manifold_name = shift;
    my %params        = @_;

    my $manifold;
    try {
        $manifold = App::Manoc::Manifold->new_manifold( $manifold_name, %params );
    }
    catch {
        my $error = "Internal error while creating manifold $manifold_name: $_";
        $self->log->debug($error);
        return;
    };

    $manifold or $self->log->debug("Manifold constructor returned undef");
    return $manifold;
}

sub _build_config_source {
    my $self   = shift;
    my $entry  = $self->device_entry;
    my $nwinfo = $self->nwinfo;

    my $manifold_name = $nwinfo->config_manifold;
    if ( !defined($manifold_name) || $manifold_name eq $nwinfo->manifold ) {
        $self->log->debug("Using common Manifold for config");
        return $self->source;
    }

    $self->log->debug("Using Manifold $manifold_name for config");
    my $host = $entry->mng_address->unpadded;

    my %params = (
        host        => $host,
        credentials => $self->credentials
    );
    my $source = $self->_create_manifold( $manifold_name, %params );

    if ( !$source ) {
        my $error = "Cannot create config source with manifold $manifold_name";
        $self->log->error($error);
        $self->task_report->add_error($error);
        return;
    }

    # auto connect
    if ( !$source->connect() ) {
        my $error = "Cannot connect to $host";
        $self->log->error($error);
        $self->task_report->add_error($error);
        return;
    }
    return $source;
}

sub _build_source {
    my $self = shift;

    my $entry  = $self->device_entry;
    my $nwinfo = $self->nwinfo;

    my $host = $entry->mng_address->unpadded;

    my $manifold_name = $nwinfo->manifold;
    $self->log->debug("Using Manifold $manifold_name");

    my %params = (
        host         => $host,
        credentials  => $self->credentials,
        extra_params => {
            mat_force_vlan => $self->config->mat_force_vlan,
        }
    );

    my $source = $self->_create_manifold( $manifold_name, %params );

    if ( !$source ) {
        my $error = "Cannot create source with manifold $manifold_name";
        $self->log->error($error);
        $self->task_report->add_error($error);
        return;
    }

    # auto connect
    if ( !$source->connect() ) {
        my $error = "Cannot connect to $host";
        $self->log->error($error);
        $self->task_report->add_error($error);
        return;
    }
    return $source;
}

sub _build_task_report {
    my $self = shift;

    $self->device_entry or return;
    my $device_address = $self->device_entry->mng_address->address;
    return App::Manoc::Netwalker::Poller::TaskReport->new( host => $device_address );
}

sub _build_uplinks {
    my $self = shift;

    my $entry      = $self->device_entry;
    my $source     = $self->source;
    my $device_set = $self->device_set;

    my %uplinks;

    # get uplink from CDP
    my $neighbors = $source->neighbors;

    # filter CDP links
    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {

            # only links to a switch
            next unless $s->{type}->{'Switch'};
            # only links to a kwnown device
            next unless $device_set->{ $s->{addr} };

            $uplinks{$p} = 1;
        }
    }

    # get uplinks from DB and merge them
    foreach ( $entry->uplinks->all ) {
        $uplinks{ $_->interface } = 1;
    }

    return \%uplinks;
}

#----------------------------------------------------------------------#
#                                                                      #
#                       D a t a   u p d a t e                          #
#                                                                      #
#----------------------------------------------------------------------#

=method update

Update device information

=cut

sub update {
    my $self = shift;

    # check if there is a device object in the DB
    my $entry = $self->device_entry;
    unless ($entry) {
        $self->log->error( "Cannot find device id ", $self->device_id );
        return;
    }

    # load netwalker info from DB
    my $nwinfo = $self->nwinfo;
    unless ($nwinfo) {
        $self->log->error( "No netwalker info for device", $entry->name );
        return;
    }

    # try to connect and update nwinfo accordingly
    $self->log->info( "Connecting to device ", $entry->name, " ", $entry->mng_address );
    if ( !$self->source ) {

        # TODO update nwinfo with connection messages
        $self->reschedule_on_failure();
        $nwinfo->offline(1);
        $nwinfo->update();
        return;
    }

    $self->update_device_info;

    # if full_update_interval is elapsed update interface table
    my $full_update_interval = $self->config->full_update_interval;
    my $elapsed_full_update  = $self->timestamp - $nwinfo->last_full_update;
    if ( $elapsed_full_update >= $full_update_interval ) {
        $self->update_if_table;

        # update nwinfo
        $nwinfo->last_full_update( $self->timestamp );
    }

    # always update CPD info
    $self->update_cdp_neighbors;

    # update required information
    $nwinfo->get_mat   and $self->update_mat;
    $nwinfo->get_arp   and $self->update_arp_table;
    $nwinfo->get_vtp   and $self->update_vtp_database;
    $nwinfo->get_dot11 and $self->update_dot11;

    $nwinfo->get_config and $self->update_config;

    $self->reschedule_on_success;
    $nwinfo->last_visited( $self->timestamp );
    $nwinfo->offline(0);
    $nwinfo->update();

    $self->log->debug( "Device ", $entry->name, " ", $entry->mng_address, "updated" );
    return 1;
}

=method update_device_info

Updates device information (model, os, vendor)  in C<nwinfo>.

=cut

sub update_device_info {
    my $self = shift;

    my $source    = $self->source;
    my $dev_entry = $self->device_entry;
    my $nw_entry  = $self->nwinfo;

    my $name = $source->name;
    $nw_entry->name($name);
    if ( defined($name) && $name ne $dev_entry->name ) {
        if ( $dev_entry->name ) {
            my $msg = "Name mismatch " . $dev_entry->name . " $name";
            $self->log->warn($msg);
        }
        else {
            $dev_entry->name($name);
            $dev_entry->update;
        }
    }

    $nw_entry->model( $source->model );
    $nw_entry->os( $source->os );
    $nw_entry->os_ver( $source->os_ver );
    $nw_entry->vendor( $source->vendor );
    $nw_entry->serial( $source->serial );

    $nw_entry->vtp_domain( $source->vtp_domain );
    $nw_entry->boottime( $source->boottime || 0 );

    $nw_entry->update;
}

=method update_cdp_neighbors

Update neighbor list in CDPNeigh

=cut

sub update_cdp_neighbors {
    my $self = shift;

    my $source      = $self->source;
    my $entry       = $self->device_entry;
    my $schema      = $self->schema;
    my $neighbors   = $source->neighbors;
    my $new_dev     = 0;
    my $cdp_entries = 0;

    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {
            my $from_dev_id = $entry->id;
            my $to_dev_obj  = App::Manoc::IPAddress::IPv4->new( $s->{addr} );

            my @cdp_entries = $self->schema->resultset('CDPNeigh')->search(
                {
                    from_device_id => $from_dev_id,
                    from_interface => $p,
                    to_device      => $to_dev_obj->padded,
                    to_interface   => $s->{port},
                }
            );

            unless ( scalar(@cdp_entries) ) {
                $self->schema->resultset('CDPNeigh')->create(
                    {
                        from_device_id => $from_dev_id,
                        from_interface => $p,
                        to_device      => $to_dev_obj,
                        to_interface   => $s->{port},
                        remote_id      => $s->{remote_id},
                        remote_type    => $s->{remote_type},
                        last_seen      => $self->timestamp,
                    }
                );
                $new_dev++;
                $cdp_entries++;
                $self->task_report->add_warning(
                    "New neighbor " . $s->{addr} . " at " . $entry->name );
                next;
            }
            my $link = $cdp_entries[0];
            $link->last_seen( $self->timestamp );
            $link->update;
            $cdp_entries++;
        }
    }
    $self->task_report->cdp_entries($cdp_entries);
    $self->task_report->new_devices($new_dev);
}

=method  update_if_table

Update interface information.

=cut

sub update_if_table {
    my $self = shift;

    my $source       = $self->source;
    my $entry        = $self->device_entry;
    my $iface_filter = $self->config->{iface_filter};

    my $ifstatus_table = $source->ifstatus_table;

    # delete old infos
    $entry->ifstatus()->delete;
    # update
    foreach my $port ( keys %$ifstatus_table ) {
        $iface_filter && lc($port) =~ /^(vlan|null|unrouted vlan)/o and next;
        my $ifstatus = $ifstatus_table->{$port};
        $entry->add_to_ifstatus(
            {
                interface => $port,
                %$ifstatus
            }
        );
    }
}

=method update_mat

Update mac address table.

=cut

sub update_mat {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->device_entry;
    my $schema = $self->schema;

    my $uplinks = $self->uplinks;
    $self->log->debug( "device uplinks: ", join( ",", keys %$uplinks ) );

    my $timestamp = $self->timestamp;
    my $device_id = $self->device_id;

    my $ignore_portchannel = $self->config->{ignore_portchannel};

    my $mat = $source->mat() or return;

    my $mat_count = 0;

    while ( my ( $vlan, $entries ) = each(%$mat) ) {
        $self->log->debug("updating mat vlan $vlan");

        if ( $vlan eq 'default' ) {
            $vlan = $self->native_vlan;
        }
        while ( my ( $m, $p ) = each %$entries ) {
            next if $uplinks->{$p};
            next if $ignore_portchannel && lc($p) =~ /^port-channel/;

            $self->schema->resultset('Mat')->register_tuple(
                macaddr   => $m,
                device_id => $device_id,
                interface => $p,
                timestamp => $timestamp,
                vlan      => $vlan,
            );

        }    # end of entries loop

    }    # end of mat loop

    $self->task_report->mat_entries($mat_count);
}

=method update_vtp_database

=cut

sub update_vtp_database {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->device_entry;

    my $vlan_db = $source->vtp_database;

    $self->log->info( "getting vtp info from ", $entry->mng_address );
    if ( !defined($vlan_db) ) {
        $self->log->error("cannot retrieve vtp info");
        $self->task_report->add_error("cannot retrieve vtp info");
        return;
    }

    $self->task_report->add_warning("Vtp Vlan DB up to date");

    my $rs = $self->schema->resultset('VlanVtp');
    $rs->delete();
    while ( my ( $id, $name ) = each(%$vlan_db) ) {
        $rs->find_or_create(
            {
                'id'   => $id,
                'name' => $name
            }
        );
    }
    my $vtp_last_update =
        $self->schema->resultset('System')->find_or_create("netwalker.vtp_update");
    $vtp_last_update->value( $self->timestamp );
    $vtp_last_update->update();

}

=method  update_arp_table

=cut

sub update_arp_table {
    my $self = shift;

    my $source    = $self->source;
    my $entry     = $self->device_entry;
    my $timestamp = $self->timestamp;
    my $vlan      = $self->arp_vlan;

    $self->log->debug("Fetching arp table ");
    my $arp_table = $source->arp_table;

    # TODO log error
    $arp_table or return;

    my $arp_count = 0;
    my ( $ip_addr, $mac_addr );
    while ( ( $ip_addr, $mac_addr ) = each(%$arp_table) ) {
        $self->log->debug( sprintf( "Arp table: %15s at %17s\n", $ip_addr, $mac_addr ) );

        $self->schema->resultset('Arp')->register_tuple(
            ipaddr    => $ip_addr,
            macaddr   => $mac_addr,
            vlan      => $vlan,
            timestamp => $timestamp,
        );
        $arp_count++;
    }

    $self->task_report->arp_entries($arp_count);
}

=method update_config

=cut

sub update_config {
    my $self = shift;

    my $device_entry    = $self->device_entry;
    my $config_date     = $device_entry->get_config_date;
    my $update_interval = $self->config->config_update_interval;
    my $timestamp       = $self->timestamp;
    my $config_source   = $self->config_source;

    unless ( $config_source->does('App::Manoc::ManifoldRole::FetchConfig') ) {
        $self->log->warnings("Config source does not support fetchconfig");
        return;
    }

    if ( !defined($config_date) || $timestamp > $config_date + $update_interval ) {
        $self->log->info( "Fetching configuration from ", $device_entry->mng_address );
        my $config_text = $config_source->configuration;
        if ( !defined($config_text) ) {
            $self->log->error( "Cannot fetch configuration from ", $device_entry->mng_address );
            return;
        }

        $self->device_entry->update_config( $config_text, $timestamp );
    }
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
