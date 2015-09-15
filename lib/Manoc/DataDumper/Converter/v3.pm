# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Converter::v3;

use Moose;
use Manoc::Utils::IPAddress qw(ip2int unpadded_ipaddr netmask2prefix);


extends 'Manoc::DataDumper::Converter::Base';

has 'device_id_map' => (
    isa => 'HashRef',
    is  => 'rw',
    lazy => 1,
    builder => '_build_device_id_map',
);

has 'device_id_counter' => (
    isa   => 'Int',
    is    => 'rw'
);

has 'network_id_counter' => (
    isa   => 'Int',
    is    => 'rw'
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
        $self->log->logdie( "No devices found while loading address->id map" );
    }

    my %id_map = map { unpadded_ipaddr( $_->mng_address ) => $_->id } @devices;
    return \%id_map;
}

sub _rewrite_device_id {
    my ( $self, $data, $column_name ) = @_;
    my $map = $self->device_id_map;

    my @new_data;
    
    foreach (@$data) {
        my $old_id = unpadded_ipaddr( $_->{$column_name} );
        my $new_id = $map->{$old_id};
        if (!defined($new_id) ) {
            $self->log->error("No id found in map for device $old_id");
            continue;
        }
        $_->{$column_name} = $new_id;
        push @new_data, $_;
    }

    @$data = @new_data;
}

sub upgrade_cdp_neigh {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'from_device');
}

sub upgrade_devices {
    my ( $self, $data ) = @_;

    my %device_id_map = ();
    my $id = $self->device_id_counter;

    foreach (@$data) {
        my $addr = $_->{id};
        my $id   = $id++;
        $_->{mng_address} = $addr;
	$_->{id}          = $id;
        $device_id_map{$addr} = $id;
    }

    $self->device_id_counter($id);
    $self->device_id_map(\%device_id_map);
}

sub upgrade_device_config {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
}

sub upgrade_dot11_assoc {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
}

sub upgrade_dot11client {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
}

sub upgrade_if_notes {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
}

sub upgrade_if_status {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
}

sub upgrade_mat {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
}


# delete session datas
sub upgrade_sessions {
    my ( $self, $data ) = @_;

    @$data = ();
}

sub upgrade_ssid_list {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
}

sub upgrade_uplinks {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'device');
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

    @$data = grep {  $_->{network} } @$data;

    foreach (@$data) {
        $_->{address}   = $_->{network};
	$_->{prefix}    = netmask2prefix($_->{netmask});
        $_->{broadcast} = $_->{to_addr};
	delete @$_{qw(from_addr to_addr network netmask parent)};
    }
}

sub after_import_IPNetwork {
    my ($self, $source) = @_;

    $self->log->info("Rebuilding IPNetwork tree");
    $source->resultset->rebuild_tree();
}

sub get_table_name_IPBlock { 'ip_range' }

sub upgrade_IPBlock {
    my ( $self, $data ) = @_;

    my $id = $self->network_id_counter;
    @$data = grep { ! $_->{network} } @$data;

    foreach (@$data) {
        $_->{id} = $id++;
	delete @$_{qw(network netmask vlan_id parent)};
    }

    $self->network_id_counter($id);
}

no Moose; # Clean up the namespace.
__PACKAGE__->meta->make_immutable();
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
