# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::ServerHW;
use strict;
use warnings;

use base 'DBIx::Class';
use Manoc::DB::Result::HWAsset;

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('serverhw');

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
        is_nullable   => 1,
    },
    n_cores_proc => {
        data_type     => 'int',
        is_nullable   => 1,
    },
    proc_freq => {
        data_type   => 'int',
        is_nullable => 1,
    },
    storage1_size => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 0
    },
    storage2_size => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 0
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('hwasset_id');

my @HWASSET_PROXY_ATTRS = qw(
                                vendor model serial inventory
                                location
                                building rack rack_level room
                        );
my  @HWASSET_PROXY_METHODS = qw(
                                   is_decommissioned is_in_warehouse is_in_rack
                                   move_to_rack move_to_room move_to_warehouse
                                   decommission
                                   display_location
                           );
__PACKAGE__->has_one(
    hwasset => 'Manoc::DB::Result::HWAsset',
    'id',
    {
        proxy => [ @HWASSET_PROXY_ATTRS, @HWASSET_PROXY_METHODS ],
    }
);


sub label {
    my $self = shift;

    return $self->inventory . " (" . $self->vendor . " - " . $self->model . ")",
}

sub new {
    my ( $self, @args ) = @_;
    my $attrs = shift @args;

    my $new_attrs = {};

    $new_attrs->{hwasset}->{type} =  Manoc::DB::Result::HWAsset->TYPE_SERVER;
    my %proxied_attrs = map { $_ => 1 } @HWASSET_PROXY_ATTRS;
    foreach my $k (keys %$attrs) {
        if ( $proxied_attrs{$k} ) {
            $new_attrs->{hwasset}->{$k} = $attrs->{$k}
        } else {
            $new_attrs->{$k} = $attrs->{$k}
        }
    }

    return $self->next::method($new_attrs, @args);
}

sub cores {
    my ($self) = @_;
    return $self->n_procs * $self->n_cores_procs;
}


__PACKAGE__->might_have(
    server => 'Manoc::DB::Result::Server',
    'serverhw_id',
    {
        cascade_update => 0,
        cascade_delete => 1,
    }
);

1;
