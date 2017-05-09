package App::Manoc::DB::Result::ServerNWInfo;
#ABSTRACT: Model object for netwalker configuration for servers

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(
    qw/+App::Manoc::DB::Helper::NetwalkerCredentials
        +App::Manoc::DB::Helper::NetwalkerPoller/
);

__PACKAGE__->table('server_nwinfo');
__PACKAGE__->add_columns(
    server_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
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

    use_sudo => {
        data_type     => 'int',
        size          => 1,
        default_value => 0,
    },

    get_packages => {
        data_type     => 'int',
        size          => 1,
        default_value => 0,
    },

    get_vms => {
        data_type     => 'int',
        size          => 1,
        default_value => 0,
    },

    update_vm => {
        data_type     => 'int',
        size          => 1,
        default_value => 0,
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

    kernel => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
        default_value => 'NULL',
    },
    kernel_ver => {
        data_type     => 'varchar',
        size          => 32,
        is_nullable   => 1,
        default_value => 'NULL',
    },

    ram_memory => {
        data_type   => 'int',
        is_nullable => 1,
    },
    cpu_model => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 32,
    },

    n_procs => {
        data_type   => 'int',
        is_nullable => 1,
    },

    boottime => {
        data_type     => 'int',
        default_value => '0',
    },
);

__PACKAGE__->make_credentials_columns;
__PACKAGE__->make_poller_columns;

__PACKAGE__->set_primary_key("server_id");

__PACKAGE__->belongs_to(
    server => 'App::Manoc::DB::Result::Server',
    { 'foreign.id' => 'self.server_id' }
);

1;
