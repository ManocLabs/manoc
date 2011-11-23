# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::IpNotes;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('ip_notes');

__PACKAGE__->add_columns(
    'ipaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15
    },
    'notes' => {
        data_type   => 'text',
        is_nullable => 1
    },
);

__PACKAGE__->set_primary_key('ipaddr');

1;
