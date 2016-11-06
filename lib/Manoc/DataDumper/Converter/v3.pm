# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Converter::v3;

use Moose;
use Manoc::Utils::IPAddress qw(padded_ipaddr netmask2prefix);

extends 'Manoc::DataDumper::Converter::Base';

has 'device_id_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_device_id_map',
);

has 'device_id_counter' => (
    isa     => 'Int',
    is      => 'rw',
    default => 1
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

has 'network_id_counter' => (
    isa => 'Int',
    is  => 'rw'
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

sub _build_hwasset_id_counter {
    my $self = shift;

    my $id = $self->schema->resultset('HWAsset')
        ->search({})->get_column('id')->max();

    return defined($id) ? $id + 1 : 1;
}

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

        $_->{hwasset_id}      = $self->device_hwasset_map->{$addr};

        # we have changed foreign key name
        $_->{rack_id}         = $_->{rack};

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
                )
        };
    }

    $self->device_id_counter($id);
    $self->device_id_map( \%device_id_map );
}

sub get_table_name_DeviceNWInfo { 'devices' }

sub upgrade_DeviceNWInfo {
    my ( $self, $data ) = @_;

    my @new_data;

    foreach (@$data) {
        my $r = {};
        $r->{get_config}         = $_->{backup_enable};
        $r->{get_arp}            = $_->{get_arp};
        $r->{get_mat}            = $_->{get_mat};
        $r->{get_dot11}          = $_->{get_dot11};
        $r->{mat_native_vlan_id} = $_->{mat_native_vlan};
        $r->{arp_vlan_id}        = $_->{vlan_arpinfo};
        $r->{username}           = '';
        $r->{password}           = $_->{telnet_pwd};
        $r->{password2}          = $_->{enable_pwd};
        $r->{snmp_community}     = $_->{snmp_com};
        $r->{snmp_user}          = $_->{snmp_user};
        $r->{snmp_password}      = $_->{snmp_password};
        $r->{snmp_version}       = $_->{snmp_ver};

        $r->{model}              = $_->{model};
        $r->{serial}             = $_->{serial};
        $r->{os}                 = $_->{os};
        $r->{os_ver}             = $_->{os_ver};
        $r->{vtp_domain}         = $_->{vtp_domain};

        $r->{device}   = $_->{id};
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

    my $id   = $self->hwasset_id_counter;
    my $type =  Manoc::DB::Result::HWAsset->TYPE_DEVICE;
    my $location = Manoc::DB::Result::HWAsset->LOCATION_RACK;

    foreach (@$data) {
        my $addr     = $_->{id};
        my $asset_id = $id++;

        my $r             = {};
        $r->{id}         = $asset_id;
        $r->{model}      = $_->{model};
        $r->{vendor}     = $_->{vendor};
        $r->{serial}     = $_->{serial};
        $r->{rack_id}    = $_->{rack};
        $r->{rack_level} = $_->{level};
        $r->{type}       = $type;
        $r->{location}   = $location;


         $r->{inventory}  =
             sprintf("%s%06d", $type, $asset_id);

         $device_hwasset_map{$addr} = $asset_id;

         push @new_data, $r;
     }

    $self->hwasset_id_counter($id);
    $self->device_hwasset_map( \%device_hwasset_map );
    @$data = @new_data;
}

sub upgrade_if_notes {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub upgrade_if_status {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' => 'device_id' );
}

sub upgrade_mat {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device', 'device_id' );
}

sub upgrade_racks {
    my ( $self, $data ) = @_;

    foreach (@$data) {
        $_->{room} = '';
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
    $self->_rewrite_device_id( $data, 'device' => 'device_id'  );
}

sub upgrade_users {
    my ( $self, $data ) = @_;

    foreach (@$data) {
        $_->{username} = $_->{login};
        delete $_->{login};

        $_->{username} eq 'admin' and $_->{superadmin} = 1;
    }
}

sub upgrade_vlan {
    my ( $self, $data ) = @_;

    foreach (@$data) {
        $_->{vlan_range_id} = $_->{vlan_range};
        delete $_->{vlan_range};
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
