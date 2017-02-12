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
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    hwasset_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
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
        data_type   => 'int',
        is_nullable => 1,
    },
    n_cores_proc => {
        data_type   => 'int',
        is_nullable => 1,
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

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/hwasset_id/] );


my @HWASSET_PROXY_ATTRS = qw(
    location
    vendor model serial inventory
    building_id rack_id rack_level room
);
my @HWASSET_PROXY_METHODS = qw(
    building rack
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

__PACKAGE__->might_have(
    server => 'Manoc::DB::Result::Server',
    'serverhw_id',
    {
        cascade_update => 0,
        cascade_delete => 1,
    }
);


sub new {
    my ( $self, @args ) = @_;
    my $attrs = shift @args;

    my $new_attrs = {
        'hwasset',
        {
            type      => Manoc::DB::Result::HWAsset->TYPE_SERVER,
            location  => Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE,
            model     => $attrs->{model},
            vendor    => $attrs->{vendor},
            inventory => $attrs->{inventory},
        }
    };

    $new_attrs->{hwasset}->{type} = Manoc::DB::Result::HWAsset->TYPE_SERVER;
    my %proxied_attrs = map { $_ => 1 } @HWASSET_PROXY_ATTRS;
    foreach my $k ( keys %$attrs ) {
        if ( $proxied_attrs{$k} ) {
            $new_attrs->{hwasset}->{$k} = $attrs->{$k};
        }
        else {
            $new_attrs->{$k} = $attrs->{$k};
        }
    }

    return $self->next::method( $new_attrs, @args );
}

sub insert {
    my ( $self, @args ) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    # pre-create hwasset if needed
    # so that hwasset_id is not null
    my $hwasset = $self->hwasset;
    if ( ! $hwasset->in_storage ) {
        $hwasset->insert;
        $self->hwasset_id($hwasset->id);
    }

    $self->next::method(@args);
    $guard->commit;
    return $self;
}


sub cores {
    my ($self) = @_;
    return $self->n_procs * $self->n_cores_procs;
}

sub label {
    my $self = shift;

    return $self->inventory . " (" . $self->vendor . " - " . $self->model . ")",;
}

sub in_use { defined( shift->server ); }

1;
