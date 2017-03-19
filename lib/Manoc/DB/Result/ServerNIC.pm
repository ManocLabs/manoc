# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::ServerNIC;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('server_nic');
__PACKAGE__->add_columns(
   id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },

    server_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

    macaddr => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },

   # primary static address.. if any
   ipaddr => {
        data_type    => 'varchar',
        is_nullable  => 1,
        size         => 15,
        ipv4_address => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( ['server_id', 'macaddr'] );

__PACKAGE__->belongs_to(
    server => 'Manoc::DB::Result::Server',
    { 'foreign.id' => 'self.server_id' }
);

=head1 NAME

Manoc::DB::Result::ServerNWIC - Server additional network interface

=head1 DESCRIPTION

A model object to mantain netwalker configuration for a server.

=cut

1;
