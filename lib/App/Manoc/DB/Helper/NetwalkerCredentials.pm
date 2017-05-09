package App::Manoc::DB::Helper::NetwalkerCredentials;
#ABSTRACT: Helper for creating credentials columns needed by netwalker pollers

use strict;
use warnings;

##VERSION

use parent 'DBIx::Class';

=method make_credentials_columns

Add all the columns required for netwalker credentials support

=cut

sub make_credentials_columns {
    my $self = shift;

    $self->add_columns(
        username => {
            data_type     => 'varchar',
            size          => 64,
            default_value => 'NULL',
            is_nullable   => 1,
        },
        password => {
            data_type     => 'varchar',
            size          => 64,
            default_value => 'NULL',
            is_nullable   => 1,
        },
        password2 => {
            data_type     => 'varchar',
            size          => 64,
            default_value => 'NULL',
            is_nullable   => 1,
        },

        use_ssh_key => {
            data_type     => 'int',
            size          => 1,
            default_value => 'NULL',
            is_nullable   => 1,
        },

        key_path => {
            data_type     => 'varchar',
            size          => 256,
            default_value => 'NULL',
            is_nullable   => 1,
        },

        snmp_community => {
            data_type     => 'varchar',
            size          => 64,
            default_value => 'NULL',
            is_nullable   => 1,
        },
        snmp_user => {
            data_type     => 'varchar',
            size          => 50,
            default_value => 'NULL',
            is_nullable   => 1,
        },
        snmp_password => {
            data_type     => 'varchar',
            size          => 50,
            default_value => 'NULL',
            is_nullable   => 1,
        },
        snmp_version => {
            data_type     => 'int',
            size          => 1,
            default_value => '0',
        },
    );
}

=method get_credentials_hash

Return all credential data as a hashref

=cut

sub get_credentials_hash {
    my $self = shift;

    return {
        username       => $self->username,
        password       => $self->password,
        password2      => $self->password2,
        use_ssh_key    => $self->use_ssh_key,
        key_path       => $self->key_path,
        snmp_community => $self->snmp_community,
        snmp_user      => $self->snmp_user,
        snmp_password  => $self->snmp_password,
        snmp_version   => $self->snmp_version,
    };
}

1;
