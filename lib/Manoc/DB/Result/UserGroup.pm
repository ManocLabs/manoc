# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::UserGroup;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('user_groups');
__PACKAGE__->add_columns(
    user_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    group_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    }
);

__PACKAGE__->set_primary_key(qw/user_id group_id/);

__PACKAGE__->belongs_to( user       => 'Manoc::DB::Result::User',  'user_id' );
__PACKAGE__->belongs_to( user_group => 'Manoc::DB::Result::Group', 'group_id' );

=head1 NAME

Manoc::DB::Result::UserGroup - A model object representing the JOIN between Users and
Groups.

=head1 DESCRIPTION

This is an object that represents a row in the 'user_groups' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
