# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::VirtualMachine;
use base 'DBIx::Class';

use strict;
use warnings;

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('virtual_machines');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    identifier => {
        data_type   => 'varchar',
        size        => 36,
    },
    name => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15,
    },

    # the virtual infrastructure is running the
    virtinfr_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

    # the hypervisor which is hosting this server
    hypervisor_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    ram_memory => {
        data_type   => 'int',
        is_nullable => 1,
    },

    vcpus => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 1
    },

    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    virtinfr => 'Manoc::DB::Result::VirtualInfr',
    'virtinfr_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->belongs_to(
    hypervisor => 'Manoc::DB::Result::Server',
    'hypervisor_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->might_have(
    server => 'Manoc::DB::Result::Server',
    'vm_id',
);

sub label {
    my $self = shift;

    my $label = $self->name;
    if ( $self->virtinfr ) {
        $label .= ' - ' . $self->virtinfr->name;
    } elsif ( $self->hypervisor ) {
        $label .= ' -' . $self->virtinfr->hostname;
    }
    return $label;
}

1;
