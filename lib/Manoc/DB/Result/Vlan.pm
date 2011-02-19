# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Vlan;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('vlan');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'integer',
        is_nullable => 0
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    },
    description => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1
    },
    vlan_range => {
        data_type      => 'integer',
        is_nullable    => 0,
        is_foreign_key => 1
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( ranges => 'Manoc::DB::Result::IPRange', 'vlan_id' );
__PACKAGE__->belongs_to( vlan_range => 'Manoc::DB::Result::VlanRange' );

=head1 NAME

Manoc::DB::Result::Vlan - A model object representing the table vlan

=head1 DESCRIPTION

This is an object that represents a row in the 'vlan' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
