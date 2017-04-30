# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::DHCPLease;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dhcp_lease');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
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

    'dhcp_server_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

__PACKAGE__->belongs_to(
    dhcp_server => 'App::Manoc::DB::Result::DHCPServer',
    { 'foreign.id' => 'self.dhcp_server_id' },
);

__PACKAGE__->set_primary_key('id');

1;
