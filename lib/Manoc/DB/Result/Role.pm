# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Role;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('roles');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    role => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['role'] );

__PACKAGE__->has_many( map_user_role => 'Manoc::DB::Result::UserRole', 'role_id' );
__PACKAGE__->many_to_many( users => 'map_user_role', 'user' );

=head1 NAME

Manoc::DB::Result::Role - A model object representing a class of access permissions to
the system.

=head1 DESCRIPTION

This is an object that represents a row in the 'roles' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
