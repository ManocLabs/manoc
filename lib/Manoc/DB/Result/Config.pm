# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Config;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('config');

__PACKAGE__->add_columns(
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'value' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255
    },
);

__PACKAGE__->set_primary_key('name');

1;
