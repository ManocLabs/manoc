# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::VlanVtp;

use parent qw(DBIx::Class::Core);
use strict;
use warnings;

__PACKAGE__->table('vlan_vtp');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'int',
        is_nullable => 0
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    }
);

__PACKAGE__->set_primary_key('id');


__PACKAGE__->belongs_to(
    vlan => 'Manoc::DB::Result::Vlan',
    { 'foreign.id' => 'self.id' },
    {
	join_type => 'LEFT',
    	is_foreign_key_constraint => 0,
    }
);

=head1 NAME

Manoc::DB::Result::VlanVtp - A model object representing a class of access permissions to the system.

=head1 DESCRIPTION

This is an object that represents a row in the 'vlan' table of your
application database (retrieved  by vtp).  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
