# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Oui;

use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('oui');

# prefix must be lowercase!

__PACKAGE__->add_columns(
    'prefix' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 8
    },
    'vendor' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
);

__PACKAGE__->set_primary_key('prefix');

1;
