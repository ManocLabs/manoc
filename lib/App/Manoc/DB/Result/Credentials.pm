package App::Manoc::DB::Result::Credentials;
#ABSTRACT: Model object for netwalker configuration for servers

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('credentials');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },

    name => {
        data_type     => 'varchar',
        size          => 128,
        default_value => 'NULL',
        is_nullable   => 1,
    },

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

    become_password => {
        data_type     => 'varchar',
        size          => 64,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    use_user => {
        data_type     => 'int',
        size          => 1,
        default_value => 0,
    },

    ssh_key => {
        data_type     => 'text',
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

=method get_credentials_hash

Return all credential data as a hashref

=cut

sub get_credentials_hash {
    my $self = shift;

    return {
        username        => $self->username,
        password        => $self->password,
        become_password => $self->become_password,
        ssh_key         => $self->ssh_key,
        snmp_community  => $self->snmp_community,
        snmp_user       => $self->snmp_user,
        snmp_password   => $self->snmp_password,
        snmp_version    => $self->snmp_version,
    };
}

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
    device_nw_info => 'App::Manoc::DB::Result::DeviceNWInfo',
    { 'foreign.credentials_id' => 'self.id' },
    {
        cascade_delete => 0,
        cascade_copy   => 0,
    }
);

__PACKAGE__->has_many(
    server_nw_info => 'App::Manoc::DB::Result::ServerNWInfo',
    { 'foreign.credentials_id' => 'self.id' },
    {
        cascade_delete => 0,
        cascade_copy   => 0,
    }
);

1;
