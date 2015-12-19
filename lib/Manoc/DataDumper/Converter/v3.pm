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
    isa => 'Int',
    is  => 'rw'
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

sub _rewrite_device_id {
    my ( $self, $data, $column_name ) = @_;
    my $map = $self->device_id_map;

    my @new_data;
    foreach (@$data) {
        my $old_id = padded_ipaddr( $_->{$column_name} );
        my $new_id = $map->{$old_id};
        if ( !defined($new_id) ) {
            $self->log->error("No id found in map for device $old_id");
            next;
        }
        $_->{$column_name} = $new_id;
        push @new_data, $_;
    }

    @$data = @new_data;
}

sub upgrade_cdp_neigh {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'from_device' );
}

sub upgrade_Device {
    my ( $self, $data ) = @_;

    my %device_id_map = ();
    my $id            = $self->device_id_counter;

    foreach (@$data) {
        my $addr = $_->{id};
        my $id   = $id++;
        $_->{mng_address}     = $addr;
        $_->{id}              = $id;
        $device_id_map{$addr} = $id;

        delete @$_{
            qw(backup_enable
                get_arp get_mat get_dot11
                mat_native_vlan  vlan_arpinfo
                telnet_pwd enable_pwd
                snmp_com snmp_user
                snmp_password snmp_ver
                last_visited offline
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
        $r->{get_config}      = $_->{backup_enable};
        $r->{get_arp}         = $_->{get_arp};
        $r->{get_mat}         = $_->{get_mat};
        $r->{get_dot11}       = $_->{get_dot11};
        $r->{mat_native_vlan} = $_->{mat_native_vlan};
        $r->{arp_vlan}        = $_->{vlan_arpinfo};
        $r->{username}        = '';
        $r->{password}        = $_->{telnet_pwd};
        $r->{password2}       = $_->{enable_pwd};
        $r->{snmp_community}  = $_->{snmp_com};
        $r->{snmp_user}       = $_->{snmp_user};
        $r->{snmp_password}   = $_->{snmp_password};
        $r->{snmp_version}    = $_->{snmp_ver};

        $r->{device}   = $_->{id};
        $r->{manifold} = 'SNMP';
        push @new_data, $r;
    }

    @$data = @new_data;
    $self->_rewrite_device_id( $data, 'device' );
}

sub upgrade_device_config {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );

    foreach (@$data) {
        delete $_->{last_visited};
    }
}

sub upgrade_dot11_assoc {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );
}

sub upgrade_dot11client {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );
}

sub upgrade_if_notes {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );
}

sub upgrade_if_status {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );
}

sub upgrade_mat {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );
}

# delete session datas
sub upgrade_sessions {
    my ( $self, $data ) = @_;

    @$data = ();
}

sub upgrade_ssid_list {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );
}

sub upgrade_uplinks {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id( $data, 'device' );
}

sub upgrade_users {
    my ( $self, $data ) = @_;

    foreach (@$data) {
        $_->{username} = $_->{login};
        delete $_->{login};
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
