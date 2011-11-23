# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::IpNotes;
use base 'DBIx::Class';

use Manoc::Utils;

use strict;
use warnings;

__PACKAGE__->load_components(qw/FilterColumn Core/);
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

__PACKAGE__->filter_column(
			   ipaddr => {
			       filter_to_storage   => sub { Manoc::Utils::padded_ipaddr($_[1]) },
			       filter_from_storage => sub { Manoc::Utils::unpadded_ipaddr($_[1]) },
				     },
			  );

1;
