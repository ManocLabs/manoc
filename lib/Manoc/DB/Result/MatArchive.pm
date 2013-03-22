# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::MatArchive;

use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('mat_archive');

__PACKAGE__->add_columns(
    'device_id' => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },
    'firstseen' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11
    },
    'lastseen' => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },
    'vlan' => {
        data_type     => 'int',
        default_value => 1,
        is_nullable   => 0,
        size          => 11
    },
);

__PACKAGE__->set_primary_key( 'device_id', 'macaddr', 'firstseen', 'vlan' );
__PACKAGE__->belongs_to( device => 'Manoc::DB::Result::DeletedDevice', 'device_id' );

__PACKAGE__->inflate_column(
			    device_id => {
					  inflate =>
					  sub { return Manoc::IpAddress::Ipv4->new({ padded => $_[0] }) if defined($_[0]) },
					  deflate => sub { return scalar $_[0]->padded if defined($_[0]) },
					 } 
			   );


1;

