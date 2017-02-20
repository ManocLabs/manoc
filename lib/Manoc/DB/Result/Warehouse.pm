# Copyright 2017 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Warehouse;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('warehouses');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
        size      => '32',
    },
    building_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    floor => {
        data_type   => 'varchar',
        size        => '4',
        is_nullable => 1,
    },
    room => {
        data_type   => 'varchar',
        size        => '16',
        is_nullable => 1,
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->belongs_to(
    building => 'Manoc::DB::Result::Building',
    'building_id',
    { join_type => 'LEFT' }
);

__PACKAGE__->has_many(
    hwassets => 'Manoc::DB::Result::HWAsset',
    'warehouse_id',
    { cascade_delete => 0, }
);

sub label {
    my $self = shift;
    return
        $self->building ? $self->name . " (" . $self->building->name . ")" :
        $self->name;
}

1;
