package App::Manoc::DB::Result::User;
#ABSTRACT: A model object representing a person with access to the system.

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use Digest::MD5 qw(md5_base64);    # for old password
use Try::Tiny;

__PACKAGE__->load_components(qw(EncodedColumn));

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

__PACKAGE__->has_many( map_user_role => 'App::Manoc::DB::Result::UserRole', 'user_id' );
__PACKAGE__->many_to_many( user_roles => 'map_user_role', 'role' );

__PACKAGE__->has_many( map_user_group => 'App::Manoc::DB::Result::UserGroup', 'user_id' );
__PACKAGE__->many_to_many( groups => 'map_user_group', 'user_group' );

=method group_roleset

Return an hash listing all the roles associated to the user via user groups.

=cut

# Just add this accessor, the map function does the expansion:
sub group_roleset {
    my $self  = shift;
    my $roles = {};
    foreach my $group ( $self->groups ) {
        foreach my $role ( $group->roles ) {
            $roles->{ $role->role } = 1;
        }
    }
    return $roles;
}

=method roleset

Return an hash listing all the roles associated to the user,
 both group based and personal.

=cut

sub roleset {
    my $self = shift;

    my $roles = $self->group_roleset();
    foreach my $role ( $self->user_roles ) {
        $roles->{ $role->role } = 1;
    }
    return $roles;
}

=method roles

Return a string listing all the roles associated to the user separated by space.
To be used in UI.

=cut

sub roles {
    return join( ",", keys( %{ shift->roleset } ) );
}

=method check_password

Used for Catalyst authentication.

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
