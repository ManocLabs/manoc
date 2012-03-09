# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::IPRange;

use base 'DBIx::Class';
use strict;
use warnings;

use Manoc::Utils;

__PACKAGE__->load_components(qw/FilterColumn Core/);
__PACKAGE__->table('ip_range');

__PACKAGE__->add_columns(
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'network' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 15
    },
    'netmask' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 15
    },
    'from_addr' => {
        data_type   => 'varchar',
        size        => '15',
        is_nullable => 0
    },
    'to_addr' => {
        data_type   => 'varchar',
        size        => '15',
        is_nullable => 0
    },
    'description' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 255
    },
    'parent' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64
    },
    'vlan_id' => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    }
);
__PACKAGE__->set_primary_key('name');
__PACKAGE__->add_unique_constraint( [ 'from_addr', 'to_addr' ] );
__PACKAGE__->belongs_to( parent  => 'Manoc::DB::Result::IPRange' );
__PACKAGE__->belongs_to( vlan_id => 'Manoc::DB::Result::Vlan' );
__PACKAGE__->has_many(
    children => 'Manoc::DB::Result::IPRange',
    { 'foreign.parent' => 'self.name' }
);
__PACKAGE__->resultset_attributes( { order_by => [ 'from_addr', 'to_addr' ] } );

foreach my $col (qw(from_addr to_addr network netmask)) {
    __PACKAGE__->inflate_column(
			$col => {
			      inflate => sub { return Manoc::Ipv4->new({addr => shift})},
			      deflate => sub { return scalar shift->padded },
				}
			       );
}

1;
