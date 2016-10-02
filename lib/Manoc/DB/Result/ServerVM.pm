# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::ServerVM;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('servers');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    identifier => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 36,
    },
    name => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15,
    },

    # the virtual infrastructure is running the
    on_virtinfr_id => {
        data_type      => 'int',
        is_foreign_key => 1,
    },

    # the hypervisor which is hosting this server
    on_hypervisor_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    ram_memory => {
        data_type   => 'int',
        is_nullable => 0,
    },

    vcpus => {
        data_type     => 'int',
        is_nullable   => 0,
        default_value => 1
    },

    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    on_virtinfr => 'Manoc::DB::Result::VirtualInfr',
    'on_virtinfr_id',
);

__PACKAGE__->belongs_to(
    on_hypervisor => 'Manoc::DB::Result::Server',
    'on_hypervisor_id',
    {
        join_type => 'left',
    }
);

1;
