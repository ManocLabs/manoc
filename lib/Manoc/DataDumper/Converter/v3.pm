# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Converter::v3;

use Moose;
use Data::Dumper;
extends 'Manoc::DataDumper::Converter';

has 'device_id_map' => (
    isa => 'HashRef',
    is  => 'rw',
    lazy => 1,
    builder => '_build_device_id_map',
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

    my %id_map = map { $_->mng_address => $_->id } @devices;
    return \%id_map;
}

sub _rewrite_device_id {
    my ( $self, $data, $column_name ) = @_;
    my $map = $self->device_id_map;

    foreach (@$data) {
        my $old_id = $_->{$column_name};
        my $new_id = $map->{$old_id};
        $new_id or $self->log->logdie("No id found in map for device $old_id");
        $_->{$column_name} = $new_id;
    }
}

sub upgrade_cdp_neigh {
    my ( $self, $data ) = @_;
    $self->_rewrite_device_id($data, 'from_device');
}

sub upgrade_devices {
    my ( $self, $data ) = @_;

    my %device_id_map = ();
    my $id = 1;

    foreach (@$data) {
        my $addr = $_->{id};
        my $id   = $id++;
        $_->{mng_address} = $addr;
	$_->{id}          = $id;
        $device_id_map{$addr} = $id;
    }

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
    return 0;
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


no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
