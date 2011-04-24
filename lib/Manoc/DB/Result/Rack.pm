# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Rack;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

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
    building => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    floor => {
        data_type   => 'int',
        is_nullable => 0,
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->belongs_to( building => 'Manoc::DB::Result::Building' );
__PACKAGE__->has_many(
    devices => 'Manoc::DB::Result::Device',
    'rack', { cascade_delete => 0 }
);

1;
