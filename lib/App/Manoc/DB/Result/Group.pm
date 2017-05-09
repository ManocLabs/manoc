package App::Manoc::DB::Result::Group;
#ABSTRACT: A model object for user groups

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('groups');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    },
    description => {
        data_type   => 'text',
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->add_unique_constraint( ['name'] );

__PACKAGE__->has_many( map_user_role => 'App::Manoc::DB::Result::GroupRole', 'group_id' );
__PACKAGE__->many_to_many( roles => 'map_user_role', 'role' );

__PACKAGE__->has_many( map_user_group => 'App::Manoc::DB::Result::UserGroup', 'group_id' );
__PACKAGE__->many_to_many( users => 'map_user_group', 'user' );

=head1 NAME

Manoc:DB::Group - A model object representing a group of users
the system.

=head1 DESCRIPTION

This is an object that represents a row in the 'groups' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
