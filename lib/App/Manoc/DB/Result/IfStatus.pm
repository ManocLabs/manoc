# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::IfStatus;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->table('if_status');

__PACKAGE__->add_columns(
    'device_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'interface' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'description' => {
        data_type     => 'varchar',
        size          => 128,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'up' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'up_admin' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'duplex' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'duplex_admin' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'speed' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'stp_state' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'cps_enable' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'cps_status' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'cps_count' => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'vlan' => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 'NULL'
    },
);

__PACKAGE__->add_relationship(
    mat_entry => 'App::Manoc::DB::Result::Mat',
    {
        'foreign.device_id' => 'self.device_id',
        'foreign.interface' => 'self.interface'
    },
    {
        accessor                  => 'single',
        join_type                 => 'LEFT',
        is_foreign_key_constraint => 0,
    },
);

__PACKAGE__->belongs_to( device => 'App::Manoc::DB::Result::Device', 'device_id' );
__PACKAGE__->set_primary_key( 'device_id', 'interface' );

__PACKAGE__->resultset_class('App::Manoc::DB::ResultSet::IfStatus');

1;
