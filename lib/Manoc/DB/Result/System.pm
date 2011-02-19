# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::System;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('system');

__PACKAGE__->add_columns(
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'value' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
);

__PACKAGE__->set_primary_key('name');

1;
