# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;
use warnings;

package Manoc::DB;

our $VERSION = 4;

our $DEFAULT_ADMIN_PASSWORD = 'admin';

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

sub get_version {
    return $VERSION;
}

our $DEFAULT_CONFIG = {
    connect_info => {
        dsn      => $ENV{MANOC_DB_DSN}      || 'dbi:SQLite:manoc.db',
        user     => $ENV{MANOC_DB_USERNAME} || undef,
        password => $ENV{MANOC_DB_PASSWORD} || undef,

        # dbi_attributes
        quote_names => 1,

        # extra attributes
        AutoCommit => 1,
    },
};

sub init_admin {
    my ($self) = @_;

    my $admin_user = $self->resultset('User')->update_or_create(
        {
            username   => 'admin',
            fullname   => 'Administrator',
            active     => 1,
            password   => $DEFAULT_ADMIN_PASSWORD,
            superadmin => 1,
            agent      => 0,
        }
    );
}

sub init_vlan {
    my ($self) = @_;

    my $rs = $self->resultset('VlanRange');
    if ( $rs->count() > 0 ) {
        return;
    }
    my $vlan_range = $rs->update_or_create(
        {
            name        => 'sample',
            description => 'sample range',
            start       => 1,
            end         => 10,
        }
    );
    $vlan_range->add_to_vlans( { name => 'native', id => 1 } );
}

sub init_ipnetwork {
    my ($self) = @_;

    my $rs = $self->resultset('IPNetwork');

    $rs->count() > 0 and return;
    $rs->update_or_create(
        {
            address => Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 16,
            name    => 'My Corp network'
        }
    );
    $rs->update_or_create(
        {
            address => Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 22,
            name    => 'Server Farm'
        }
    );
    $rs->update_or_create(
        {
            address => Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 24,
            name    => 'Yellow zone'
        }
    );
    $rs->update_or_create(
        {
            address => Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 24,
            name    => 'Yellow zone'
        }
    );
    $rs->update_or_create(
        {
            address => Manoc::IPAddress::IPv4->new("10.10.1.0"),
            prefix  => 24,
            name    => 'Green zone'
        }
    );
    $rs->update_or_create(
        {
            address => Manoc::IPAddress::IPv4->new("10.10.5.0"),
            prefix  => 23,
            name    => 'Workstations'
        }
    );
}

sub init_roles {
    my ( $self, $conf_roles ) = @_;

    my $rs = $self->resultset('Role');

    my $default_roles = \%Manoc::CatalystRole::Permission::DEFAULT_ROLES;
    my $roles = Catalyst::Utils::merge_hashes( $default_roles, $conf_roles );

    foreach my $role ( keys %$roles ) {
        $rs->update_or_create( { role => $role } );
    }

}

sub init_management_url {
    my ($self) = @_;
    my $rs = $self->resultset('MngUrlFormat');
    $rs->update_or_create(
        {
            name   => 'telnet',
            format => 'telnet:%h',
        }
    );
    $rs->update_or_create(
        {
            name   => 'ssh',
            format => 'ssh:%h',
        }
    );
    $rs->update_or_create(
        {
            name   => 'http',
            format => 'http://:%h',
        }
    );
    $rs->update_or_create(
        {
            name   => 'https',
            format => 'https://:%h',
        }
    );
}

1;
