# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::DHCPReservation;

use base 'DBIx::Class';

use Manoc::Utils;

use strict;
use warnings;

__PACKAGE__->load_components(qw/FilterColumn Core /);
__PACKAGE__->table('dhcp_reservation');

__PACKAGE__->add_columns(
    'server' => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },

    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },

    'ipaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15
    },

    'name' => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },

    'hostname' => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },

);

__PACKAGE__->set_primary_key( 'server', 'ipaddr', 'macaddr' );

__PACKAGE__->filter_column(
			   ipaddr => {
			       filter_to_storage   => sub { Manoc::Utils::padded_ipaddr($_[1]) },
			       filter_from_storage => sub { Manoc::Utils::unpadded_ipaddr($_[1]) },
				     },
			  );

1;
