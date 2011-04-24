# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::VlanRange;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('vlan_range');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    start => {
        data_type   => 'int',
        is_nullable => 0,
        extras      => { unsigned => 1 }
    },
    end => {
        data_type   => 'int',
        is_nullable => 0,
        extras      => { unsigned => 1 }
    },
    description => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['name'] );
__PACKAGE__->has_many( vlans => 'Manoc::DB::Result::Vlan', 'vlan_range' );

=head1 NAME

Manoc::DB::Result::Vlan - A model object representing the table vlan_range

=head1 DESCRIPTION

This is an object that represents a row in the 'vlan_range' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
