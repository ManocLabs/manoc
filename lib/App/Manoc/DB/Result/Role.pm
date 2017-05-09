package App::Manoc::DB::Result::Role;
#ABSTRACT:  A model object representing a class of access permissions to the system.

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

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

__PACKAGE__->has_many( map_user_role => 'App::Manoc::DB::Result::UserRole', 'role_id' );
__PACKAGE__->many_to_many( users => 'map_user_role', 'user' );

1;
