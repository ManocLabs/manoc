# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Ip;

use parent 'Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('ip');

__PACKAGE__->add_columns(
    'ipaddr' => {
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
    },
    'description' => {
        data_type   => 'text',
        is_nullable => 1,
    },
    'assigned_to' => {
        data_type   => 'varchar',
        size        => 45,
        is_nullable => 1,
    },
    'phone' => {
        data_type   => 'varchar',
        size        => 30,
        is_nullable => 1,
    },
    'email' => {
        data_type   => 'varchar',
        is_nullable => 45,
    },
    'notes' => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('ipaddr');

1;
