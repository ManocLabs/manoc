# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Dot11Assoc;

use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn/);
__PACKAGE__->table('dot11_assoc');

__PACKAGE__->add_columns(
    'device' => {
        data_type      => 'varchar',
        is_nullable    => 0,
        size           => 15,
        is_foreign_key => 1,
    },
    'ssid' => {
        data_type   => 'varchar',
        size        => 128,
        is_nullable => 0,
    },
    'ipaddr' => {
        data_type   => 'varchar',
        size        => 15,
        is_nullable => 1,
    },
    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },
    'vlan' => {
        data_type     => 'int',
        default_value => 1,
        is_nullable   => 0,
        size          => 11
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
    'archived' => {
        data_type     => 'int',
        default_value => 0,
        is_nullable   => 0,
        size          => 1
    },
);

__PACKAGE__->set_primary_key( 'macaddr', 'device', 'firstseen', 'archived' );

__PACKAGE__->belongs_to( 'device_entry' => 'Manoc::DB::Result::Device', 'device' );

foreach my $col (qw( device ipaddr )) {
  __PACKAGE__->inflate_column(
			      $col =>  {
					inflate =>
					sub { return Manoc::IpAddress::Ipv4->new({ padded => $_[0] }) if defined($_[0]) },
					deflate => sub { return scalar $_[0]->padded if defined($_[0]) },
				       }
			     );
}




1;

