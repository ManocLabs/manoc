package App::Manoc::DB::Result::UserRole;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('user_roles');
__PACKAGE__->add_columns(
    user_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    role_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    }
);

__PACKAGE__->set_primary_key(qw/user_id role_id/);

__PACKAGE__->belongs_to( user => 'App::Manoc::DB::Result::User', 'user_id' );
__PACKAGE__->belongs_to( role => 'App::Manoc::DB::Result::Role', 'role_id' );

=head1 NAME

App::Manoc::DB::Result::UserRole - A model object representing the JOIN between Users and
Roles.

=head1 DESCRIPTION

This is an object that represents a row in the 'user_roles' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
