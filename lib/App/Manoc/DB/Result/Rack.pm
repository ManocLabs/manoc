# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::Rack;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->table('racks');
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
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    floor => {
        data_type   => 'varchar',
        size        => '4',
        is_nullable => 0,
    },
    room => {
        data_type   => 'varchar',
        size        => '16',
        is_nullable => 0,
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->belongs_to(
    building => 'App::Manoc::DB::Result::Building',
    'building_id'
);

__PACKAGE__->has_many(
    hwassets => 'App::Manoc::DB::Result::HWAsset',
    'rack_id',
    { cascade_delete => 0 }
);

__PACKAGE__->has_many(
    devices => 'App::Manoc::DB::Result::Device',
    'rack_id',
    { cascade_delete => 1 }
);

sub label {
    my $self = shift;
    return $self->name . " (" . $self->building->name . ")";
}

1;
