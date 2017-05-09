#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech   = get_mech();
my $schema = ManocTest::Schema->get_schema();

mech_login;

# visit list
$mech->get_ok('/server');
$mech->title_is('Manoc - Servers');

like( $mech->find_link( text => 'Add' )->url, qr|/server/create$|,
    "Add link points to create" );

$mech->get_ok('/server/create');
$mech->title_is('Manoc - Create server');
$mech->submit_form_ok(
    {
        form_id => 'form-server',
        fields  => {
            'form-server.hostname'      => 'servernew',
            'form-server.address'       => '192.168.1.1',
            'form-server.type'          => 'l',
            'form-server.is_hypervisor' => 0,
        }
    },
    "Create server"
);
$mech->title_is( 'Manoc - Server servernew', "Server page" );

$mech->get('/server');
$mech->follow_link_ok( { text => 'servernew' }, 'Follow link from list' );
$mech->follow_link_ok( { text => 'Edit' },      'Follow edit link' );
$mech->title_is('Manoc - Edit server');
$mech->submit_form_ok(
    {
        form_id => 'form-server',
        fields  => {
            'form-server.hostname' => 'SERVER001',
        }
    },
    "Edit server"
);
$mech->title_is( 'Manoc - Server SERVER001', "Back to server page, new name" );

$mech->follow_link_ok( { text => 'Decommission' }, 'Follow decommision link' );
$mech->submit_form_ok(
    {
        form_id => 'form-server-decommission',
        fields  => {
            'form-server-decommission.hostedvm_action' => 'KEEP',
        }
    },
    "Submit decommission form"
);
$mech->title_is( 'Manoc - Server SERVER001', "Back to server page" );

my $hw = $schema->resultset('Server')->find( { hostname => 'SERVER001' } );
ok( $hw->decommissioned, "Server is decommissioned in DB" );

$mech->follow_link_ok( { text => 'Delete' }, 'Follow delete link' );
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit delete form"
);
$mech->title_is( 'Manoc - Servers', 'Back to list page' );
$mech->content_lacks( 'SERVER001', "server is no more in list" );
is( $schema->resultset('Server')->find( { hostname => 'SERVER001' } ),
    undef, "server is deleted" );

done_testing();
