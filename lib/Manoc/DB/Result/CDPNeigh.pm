# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::CDPNeigh;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('cdp_neigh');
__PACKAGE__->add_columns(
    'from_device' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'from_interface' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'to_device' => {
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
    },
    'to_interface' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'last_seen' => {
        data_type   => 'int',
        is_nullable => 0,
    },
    'remote_id' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64
    },
    'remote_type' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64
    },
);

__PACKAGE__->set_primary_key(
    qw(from_device from_interface
        to_device to_interface)
);

__PACKAGE__->belongs_to(
    from_device => 'Manoc::DB::Result::Device',
    { 'foreign.id' => 'self.from_device' }
);

__PACKAGE__->belongs_to(
    to_device_info => 'Manoc::DB::Result::Device',
    { 'foreign.mng_address' => 'self.to_device' },
    {
        join_type                 => 'LEFT',
        is_foreign_key_constraint => 0
    },
);

=head1 NAME

Manoc::DB::Result::CDPNeigh - A model object representing a CDP relationship.

=head1 DESCRIPTION

This is an object that represents a CDP entry. It uses DBIx::Class
(aka, DBIC) to do ORM.

=cut

1;
