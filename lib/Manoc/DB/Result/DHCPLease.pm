# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::DHCPLease;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dhcp_lease');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
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
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
    },

    'hostname' => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },

    'start' => {
        data_type   => 'int',
        is_nullable => 0,
    },

    'end' => {
        data_type   => 'int',
        is_nullable => 0,
    },
    'status' => {
        data_type => 'varchar',
        size      => 16,
    },
    'dhcpnet_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

__PACKAGE__->belongs_to( 
    'dhcp_network' => 'Manoc::DB::Result::DHCPNetwork',
    { 'foreign.id' => 'self.dhcpnet_id' }, 
);

__PACKAGE__->set_primary_key('id');

1;
