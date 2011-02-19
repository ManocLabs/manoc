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
#with 'Manoc::Logger::Role';

use SQL::Translator;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    $self->log->debug('Creating admin role... done.');
    my $admin_role = $schema->resultset('Role')->update_or_create( { role => 'admin', } );
    $self->log->debug('Creating admin user... done.');
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
