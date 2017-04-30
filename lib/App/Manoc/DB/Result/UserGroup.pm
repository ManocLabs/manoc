package App::Manoc::DB::Result::UserGroup;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

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

__PACKAGE__->belongs_to( user       => 'App::Manoc::DB::Result::User',  'user_id' );
__PACKAGE__->belongs_to( user_group => 'App::Manoc::DB::Result::Group', 'group_id' );

=head1 NAME

App::Manoc::DB::Result::UserGroup - A model object representing the JOIN between Users and
Groups.

=head1 DESCRIPTION

This is an object that represents a row in the 'user_groups' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
