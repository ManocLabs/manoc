package App::Manoc::DB::Result::DeviceIfStatus;
#ABSTRACT: A model object for information on device ports status

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('device_ifstatus');

__PACKAGE__->add_columns(
    'interface_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
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

__PACKAGE__->belongs_to(
    interface => 'App::Manoc::DB::Result::DeviceIface',
    'interface_id'
);

__PACKAGE__->set_primary_key('interface_id');

=method device

Shortcut to for $row->interface->device

=cut

sub device { shift->interface->device }

1;
