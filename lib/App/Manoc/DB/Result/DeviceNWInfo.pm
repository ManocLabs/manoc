package App::Manoc::DB::Result::DeviceNWInfo;
#ABSTRACT: Model object for netwalker configuration for devices

=head1 DESCRIPTION

A model object to mantain netwalker configuration  and connection information for a device.

=cut

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::NetwalkerPoller
        /
);

__PACKAGE__->table('device_nwinfo');
__PACKAGE__->add_columns(
    device_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

    credentials_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

    manifold => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 0,
    },

    manifold_args => {
        data_type     => 'varchar',
        size          => 255,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    # manifold to be used to fetch the
    # configuration
    config_manifold => {
        data_type     => 'varchar',
        size          => 64,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    last_full_update => {
        data_type     => 'int',
        default_value => '0',
    },

    last_backup => {
        data_type     => 'int',
        default_value => '0',
    },

    netwalker_status => {
        data_type     => 'varchar',
        size          => 255,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    get_config => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    get_arp => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    get_mat => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    get_dot11 => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    get_vtp => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },

    mat_native_vlan_id => {
        data_type     => 'int',
        default_value => '1',
        is_nullable   => 1,
    },

    arp_vlan_id => {
        data_type     => 'int',
        default_value => '1',
        is_nullable   => 1,
    },

    # these fields are populated by netwalker
    # and can be compared with hwasset ones
    name => {
        data_type     => 'varchar',
        size          => 128,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    vendor => {
        data_type     => 'varchar',
        is_nullable   => 1,
        size          => 32,
        default_value => 'NULL',
    },
    model => {
        data_type     => 'varchar',
        is_nullable   => 1,
        size          => 32,
        default_value => 'NULL',
    },
    serial => {
        data_type     => 'varchar',
        is_nullable   => 1,
        size          => 32,
        default_value => 'NULL',
    },
    os => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
        default_value => 'NULL',
    },
    os_ver => {
        data_type     => 'varchar',
        size          => 32,
        is_nullable   => 1,
        default_value => 'NULL',
    },
    vtp_domain => {
        data_type     => 'varchar',
        size          => 64,
        is_nullable   => 1,
        default_value => 'NULL',
    },
    boottime => {
        data_type     => 'int',
        default_value => '0',
    },
);

__PACKAGE__->make_poller_columns;

__PACKAGE__->set_primary_key("device_id");

__PACKAGE__->belongs_to(
    device => 'App::Manoc::DB::Result::Device',
    { 'foreign.id' => 'self.device_id' }
);

__PACKAGE__->belongs_to(
    credentials => 'App::Manoc::DB::Result::Credentials',
    { 'foreign.id' => 'self.credentials_id' },
    { join_type    => 'left', on_delete => 'SET NULL' },
);

__PACKAGE__->belongs_to(
    mat_native_vlan => 'App::Manoc::DB::Result::Vlan',
    'mat_native_vlan_id'
);
__PACKAGE__->belongs_to(
    arp_vlan => 'App::Manoc::DB::Result::Vlan',
    'arp_vlan_id'
);

1;
