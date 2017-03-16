# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::ServerNWInfo;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(qw'+Manoc::DB::Helper::NetwalkerCredentials');

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

    offline => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },

    last_visited => {
        data_type     => 'int',
        default_value => '0',
    },

    netwalker_status => {
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

__PACKAGE__->set_primary_key("server_id");

__PACKAGE__->belongs_to(
    server => 'Manoc::DB::Result::Server',
    { 'foreign.id' => 'self.server_id' }
);



=head1 NAME

Manoc::DB::Result::ServerNWInfo - Server Netwalker configuration and
connection information

=head1 DESCRIPTION

A model object to mantain netwalker configuration for a server.

=cut

1;
