# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Dot11Client;

use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('dot11client');

__PACKAGE__->add_columns(
    'device' => {
        data_type      => 'varchar',
        is_nullable    => 0,
        size           => 15,
        is_foreign_key => 1,
    },
    'interface' => {
        data_type      => 'varchar',
        is_nullable    => 0,
        size           => 64,
        is_foreign_key => 1,
    },
    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },
    'ssid' => {
        data_type   => 'varchar',
        size        => 128,
        is_nullable => 0,
    },
    'ipaddr' => {
        data_type   => 'varchar',
        size        => 15,
        is_nullable => 1,
    },
    'vlan' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'parent' => {
        data_type   => 'varchar',
        size        => 17,
        is_nullable => 1,
    },
    'state' => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 1,
    },
    'u_cipher' => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 1,
    },
    'm_cipher' => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 1,
    },
    'power' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'quality' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'mic' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'wep' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'authen' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 16,
    },
    q			 'addauthen' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 16,
    },
    'dot1xauthen' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 16,
    },
    'keymgt' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 16,
    },
);

__PACKAGE__->set_primary_key( 'macaddr', 'device' );

__PACKAGE__->belongs_to( 'device_entry' => 'Manoc::DB::Result::Device', 'device' );

1;

