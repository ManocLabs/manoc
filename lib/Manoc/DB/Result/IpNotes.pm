# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::IpNotes;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn/);
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

__PACKAGE__->inflate_column(
			    ipaddr => {
				       inflate =>
				       sub { return Manoc::IpAddress::Ipv4->new({ padded => $_[0] }) if defined($_[0]) },
				       deflate => sub { return scalar $_[0]->padded if defined($_[0]) },
				      } 
			   );

1;
