#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

package App::Manoc::Script::InitDB;

use FindBin;
use lib "$FindBin::Bin/../lib";
use App::Manoc::Support;

use Moose;
use App::Manoc::Logger;
use App::Manoc::IPAddress::IPv4;

use App::Manoc::CatalystRole::Permission;
use Catalyst::Utils;

extends 'App::Manoc::Script';
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
        $self->log->info('Resetting admin user.');
        $self->schema->init_admin;
        return;
    }

    # full init
    $self->log->info('Creating admin user.');
    $self->schema->init_admin;
    $self->log->info('Creating roles.');
    my $conf_roles = $self->config->{'App::Manoc::Permission'}->{roles};
    $self->schema->init_roles($conf_roles);
    $self->log->info('Creating vlan.');
    $self->schema->init_vlan;
    $self->log->info('Creating ip network.');
    $self->schema->init_ipnetwork;
    $self->log->info('Creating management urls.');
    $self->schema->init_management_url;
}

no Moose;

package main;

my $app = App::Manoc::Script::InitDB->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
