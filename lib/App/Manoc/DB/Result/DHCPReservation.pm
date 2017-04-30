# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::DHCPReservation;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dhcp_reservation');

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

    last_modified => {
        data_type     => 'int',
        default_value => '0',
    },

    manoc_managed => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },

    on_server => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },

    'dhcp_server_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

    'dhcp_subnet_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

);

__PACKAGE__->belongs_to(
    dhcp_server => 'App::Manoc::DB::Result::DHCPServer',
    { 'foreign.id' => 'self.dhcp_server_id' },
);

__PACKAGE__->belongs_to(
    dhcp_subnet => 'App::Manoc::DB::Result::DHCPSubnet',
    { 'foreign.id' => 'self.dhcp_subnet_id' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( [ 'ipaddr', 'macaddr', 'dhcp_server_id' ] );

1;
