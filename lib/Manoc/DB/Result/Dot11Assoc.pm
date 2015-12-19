# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Dot11Assoc;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dot11_assoc');

__PACKAGE__->add_columns(
    'device' => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    'ssid' => {
        data_type   => 'varchar',
        size        => 128,
        is_nullable => 0,
    },
    'ipaddr' => {
        data_type    => 'varchar',
        size         => 15,
        is_nullable  => 1,
        ipv4_address => 1,
    },
    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },
    'vlan' => {
        data_type     => 'int',
        default_value => 1,
        is_nullable   => 0,
        size          => 11
    },
    'firstseen' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11
    },
    'lastseen' => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },
    'archived' => {
        data_type     => 'int',
        default_value => 0,
        is_nullable   => 0,
        size          => 1
    },
);

__PACKAGE__->set_primary_key( 'macaddr', 'device', 'firstseen', 'archived' );

__PACKAGE__->belongs_to( 'device_entry' => 'Manoc::DB::Result::Device', 'device' );

1;

