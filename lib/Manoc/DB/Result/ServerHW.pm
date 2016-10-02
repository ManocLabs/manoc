# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::ServerHW;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('servers');

__PACKAGE__->add_columns(
    hwasset_id => {
        data_type      => 'int',
        is_foreign_key => 1,
    },
    ram_memory => {
        data_type   => 'int',
        is_nullable => 0,
    },
    cpu_model => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32,
    },
    n_procs => {
        data_type     => 'int',
        is_nullable   => 0,
        default_value => 1
    },
    n_cores_procs => {
        data_type     => 'int',
        is_nullable   => 0,
        default_value => 1
    },
    proc_freq => {
        data_type   => 'real',
        is_nullable => 0,
    },
    storage1_size => {
        data_type     => 'real',
        is_nullable   => 0,
        default_value => 0
    },
    storage2_size => {
        data_type     => 'real',
        is_nullable   => 0,
        default_value => 0
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
    template => {
        data_type     => 'int',
        size          => '1',
        is_nullable   => '1',
        default_value => '0',
    },
);

__PACKAGE__->set_primary_key('hwasset_id');

__PACKAGE__->belongs_to(
    hwasset => 'Manoc::DB::Result::HWAsset',
    'hwasset_id',
    {
        proxy          => [qw/vendor model serial inventory/],
        cascade_update => 1,
        cascade_delete => 1
    }
);

sub cores {
    my ($self) = @_;
    return $self->n_procs * $self->n_cores_procs;
}

1;
