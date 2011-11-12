#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

package Manoc::InitDB;

use FindBin;
use lib "$FindBin::Bin/../lib";
eval { use local::lib "$FindBin::Bin/../support" };

use Moose;
use Manoc::Logger;

extends 'Manoc::App';
with 'MooseX::Getopt::Dashes';

has 'reset_admin' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

sub run {
    my ($self) = @_;

    if  ($self->reset_admin) {
        $self->do_reset_admin;
        return;
    }

    # full init
    $self->do_reset_admin;
    $self->init_vlan;
    $self->init_iprange;

}

sub do_reset_admin {
    my ($self) = @_;

    my $schema = $self->schema;
    $self->log->info('Creating admin role.');
    my $admin_role = $schema->resultset('Role')->update_or_create( { role => 'admin', } );
    $self->log->info('Creating admin user.');
    my $admin_user = $schema->resultset('User')->update_or_create(
        {
            login    => 'admin',
            fullname => 'Administrator',
            active   => 1,
            password => 'admin',
        }
    );
    $self->log->debug('Adding admin role to the admin user... done.');
    if ( $admin_user->roles->search( { role => 'admin' } )->count == 0 ) {
        $admin_user->add_to_roles($admin_role);
    }
}

sub init_vlan {
    my ($self) = @_;

    my $schema = $self->schema;
    my $rs = $schema->resultset('VlanRange');
    if ($rs->count() > 0) {
            $self->log->info('We have a VLAN range: skipping init.');
            return;
    }
    $self->log->info('Creating a sample vlan range with VLAN 1.');
    my $vlan_range = $rs->update_or_create({
        name => 'sample',
        description => 'sample range',
        start => 1,
        end   => 10,
       });
    $vlan_range->add_to_vlans({ name => 'native', id => 1 });
}

sub init_iprange {
    my ($self) = @_;

    my $schema = $self->schema;
    my $rs = $schema->resultset('IPRange');
    if ($rs->count() > 0) {
            $self->log->info('We have a IP range: skipping init.');
            return;
    }
    $self->log->info('Creating a sample IP range for 0.0.0.0/0.');
    $rs->update_or_create({
        name => 'IPV4',
        description => 'all ipv4 addresses',
        from_addr => '0.0.0.0',
        to_addr   => '255.255.255.255',
        network   => '0.0.0.0',
        netmask   => '0.0.0.0',
       });
}
no Moose;

package main;

my $app = Manoc::InitDB->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
