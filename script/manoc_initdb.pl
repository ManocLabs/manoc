#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

package Manoc::Script::InitDB;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Support;

use Moose;
use Manoc::Logger;
use Manoc::IPAddress::IPv4;

use Manoc::CatalystRole::Permission;
use Catalyst::Utils;

extends 'Manoc::Script';
with 'MooseX::Getopt::Dashes';

has 'reset_admin' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

sub run {
    my ($self) = @_;

    if ( $self->reset_admin ) {
        $self->do_reset_admin;
        return;
    }

    # full init
    $self->do_reset_admin;
    $self->init_vlan;
    $self->init_ipnetwork;
    $self->init_management_url;
    $self->init_roles;
}

sub do_reset_admin {
    my ($self) = @_;

    my $schema = $self->schema;

    $self->log->info('Creating admin user.');
    my $admin_user = $schema->resultset('User')->update_or_create(
        {
            username   => 'admin',
            fullname   => 'Administrator',
            active     => 1,
            password   => 'admin',
            superadmin => 1,
            agent      => 0,
        }
    );
}

sub init_vlan {
    my ($self) = @_;

    my $schema = $self->schema;
    my $rs     = $schema->resultset('VlanRange');
    if ( $rs->count() > 0 ) {
        $self->log->info('We have a VLAN range: skipping init.');
        return;
    }
    $self->log->info('Creating a sample vlan range with VLAN 1.');
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

    my $schema = $self->schema;
    my $rs     = $schema->resultset('IPNetwork');

    $rs->count() > 0 and return;

    $self->log->info('Creating some sample networks');

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
    my ($self) = @_;

    my $schema = $self->schema;
    my $rs     = $schema->resultset('Role');
    $self->log->info('Creating configured roles');

    my $default_roles = \%Manoc::CatalystRole::Permission::DEFAULT_ROLES;
    my $conf_roles    = $self->config->{'Manoc::Permission'}->{roles};

    my $roles = Catalyst::Utils::merge_hashes( $default_roles, $conf_roles );

    foreach my $role ( keys %$roles ) {
        $rs->update_or_create( { role => $role } );
    }

}

sub init_management_url {
    my ($self) = @_;
    my $schema = $self->schema;
    my $rs     = $schema->resultset('MngUrlFormat');
    $self->log->info('Creating default management urls');
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

no Moose;

package main;

my $app = Manoc::Script::InitDB->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
