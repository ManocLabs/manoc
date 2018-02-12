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

my $wks_hw = $schema->resultset('WorkstationHW')->create(
    {
        ram_memory => 256,
        cpu_model  => 'P5',
        vendor     => 'Pear',
        model      => 'PearBook',
        serial     => 'PBK001',
    },
);

# visit list
$mech->get_ok('/workstation');
$mech->title_is('Manoc - Workstations');

like( $mech->find_link( text => 'Add' )->url,
    qr|/workstation/create$|, "Add link points to create" );

$mech->get_ok('/workstation/create');
$mech->title_is('Manoc - Create workstation');
$mech->submit_form_ok(
    {
        form_id => 'form-workstation',
        fields  => {
            'hostname'                => 'workstationnew',
            'ethernet_static_address' => '192.168.1.1',
            'wireless_static_address' => '192.168.1.2'
        }
    },
    "Create workstation"
);
$mech->title_is( 'Manoc - Workstation workstationnew', "Workstation page" );

$mech->get('/workstation/datatable_source');
my $json = $mech->json_ok();
is( $json->{data}->[0]->{hostname}, 'workstationnew', "First entry in table is worstationnew" );
my $href = $json->{data}->[0]->{href};

$mech->get_ok( $href, 'Follow link from table json' );
$mech->follow_link_ok( { text => 'Edit' }, 'Follow edit link' );
$mech->title_is('Manoc - Edit workstation');
$mech->submit_form_ok(
    {
        form_id => 'form-workstation',
        fields  => {
            'hostname'      => 'WORKSTATION001',
            'workstationhw' => $wks_hw->id
        }
    },
    "Edit workstation"
);
$mech->title_is( 'Manoc - Workstation WORKSTATION001', "Back to workstation page, new name" );

$mech->follow_link_ok( { text => 'Decommission' }, 'Follow decommission link' );
$mech->submit_form_ok(
    {
        form_id => 'form-workstation-decommission',
        fields  => {
            'hardware_action' => 'WAREHOUSE',
        }
    },
    "Submit decommission form"
);
$mech->title_is( 'Manoc - Workstation WORKSTATION001', "Back to workstation page" );

my $hw = $schema->resultset('Workstation')->find( { hostname => 'WORKSTATION001' } );
ok( $hw->decommissioned, "Workstation is decommissioned in DB" );

$mech->follow_link_ok( { text => 'Delete' }, 'Follow delete link' );
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit delete form"
);
$mech->title_is( 'Manoc - Workstations', 'Back to list page' );

is( $schema->resultset('Workstation')->find( { hostname => 'WORKSTATION001' } ),
    undef, "workstation is deleted" );

done_testing();
