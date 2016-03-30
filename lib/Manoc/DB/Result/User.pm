# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::User;

use parent 'DBIx::Class::Core';

use strict;
use warnings;
use Digest::MD5 qw(md5_base64);    # for old password
use Try::Tiny;

__PACKAGE__->load_components(qw(PK::Auto EncodedColumn Core));

__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    username => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    },
    password => {
        data_type           => 'varchar',
        size                => 255,
        encode_column       => 1,
        encode_class        => 'Crypt::Eksblowfish::Bcrypt',
        encode_args         => { key_nul => 0, cost => 8 },
        encode_check_method => 'check_password_bcrypt',
    },
    fullname => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1
    },
    email => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1
    },
    active => {
        data_type     => 'int',
        size          => 1,
        is_nullable   => 0,
        default_value => 1,
    },
    superadmin => {
        data_type     => 'int',
        size          => 1,
        is_nullable   => 0,
        default_value => 0,
    },
    agent => {
        data_type     => 'int',
        size          => 1,
        is_nullable   => 0,
        default_value => 0,
    },
);
__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->add_unique_constraint( ['username'] );

__PACKAGE__->has_many( map_user_role => 'Manoc::DB::Result::UserRole', 'user_id' );
__PACKAGE__->many_to_many( user_roles => 'map_user_role', 'role' );

__PACKAGE__->has_many( map_user_group => 'Manoc::DB::Result::UserGroup', 'user_id' );
__PACKAGE__->many_to_many( groups => 'map_user_group', 'group' );

# Just add this accessor, the map function does the expansion:
sub all_group_roles {
    my $self  = shift;
    my $roles = {};
    foreach my $group ( $self->groups ) {
        foreach my $role ( $group->roles ) {
            $roles->{$role} = 1;
        }
    }
    return $roles;
}

sub roles {
    my $self = shift;

    my $roles = $self->all_group_roles();
    foreach my $role ( $self->user_roles ) {
        $roles->{$role} = 1;
    }
    return $roles;
}

=head1 NAME

Manoc:DB::User - A model object representing a person with access to
the system.

=head1 DESCRIPTION

This is an object that represents a row in the 'users' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

sub check_password {
    my ( $self, $attempt ) = @_;

    if ( md5_base64($attempt) eq $self->password ) {
        $self->password($attempt);
        $self->update();
        return 1;
    }

    my $ret = 0;
    try {
        $ret = $self->check_password_bcrypt($attempt);
    };
    return $ret;
}

1;
