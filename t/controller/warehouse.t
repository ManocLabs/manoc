#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech   = get_mech();
my $schema = ManocTest::Schema->get_schema();

# building used for test
my $building = $schema->resultset("Building")->create(
    {
        name        => 'B01',
        description => 'Test building',
    }
);

mech_login;

# visit (empty) rack list
$mech->get_ok('/warehouse');
$mech->title_is('Manoc - Warehouses');

like( $mech->find_link( text => 'Add' )->url,
    qr|/warehouse/create$|, "Add link points to create" );

# continue testing even if Add link is broken
$mech->get_ok( '/warehouse/create', "Create rack page" );
$mech->submit_form_ok(
    {
        form_id => 'form-warehouse',
        fields  => {
            'building' => $building->id
        },
    },
    "Submit uncomplete form",
);
$mech->text_contains('Name field is required');

# try with a correct form
$mech->submit_form_ok(
    {
        form_id => 'form-warehouse',
        fields  => {
            'name'     => 'W01',
            'floor'    => 1,
            'room'     => 'L320',
            'building' => $building->id
        },
    },
    "Create rack in building",
);
$mech->title_is( 'Manoc - Warehouse W01', 'Warehouse page' );

$mech->get('/warehouse');
$mech->text_contains( 'W01', "New warehouse in the list" );

my $warehouse = $schema->resultset("Warehouse")->find( { name => 'W01' } );
my $hwasset = $schema->resultset("HWAsset")->create(
    {
        type      => App::Manoc::DB::Result::HWAsset->TYPE_DEVICE,
        vendor    => 'IQ',
        model     => 'MegaPort 48',
        serial    => 'TestHW01',
        inventory => 'Inv001',
    }
);
$hwasset->move_to_warehouse($warehouse);
$hwasset->update;

$mech->follow_link_ok( { text => 'W01' }, "View page" );
$mech->title_is('Manoc - Warehouse W01');

$mech->follow_link_ok( { text => 'Edit' }, "Follow edit link" );
$mech->title_is('Manoc - Edit warehouse');
$mech->back();

$mech->follow_link_ok( { text => 'Delete' }, "Follow delete link" );
# first form is search box
$mech->submit_form_ok( { form_number => 2 }, "Submit delete form" );
$mech->text_contains( 'Warehouse is not empty. Cannot be deleted.',
    'Cannot delete warehouse with assets' );

$hwasset->delete();
$mech->follow_link( text => 'Delete' );
$mech->submit_form_ok( { form_number => 2 }, "Submit delete form" );

$mech->title_is( 'Manoc - Warehouses', "Back to rack list" );
$mech->content_lacks( 'W01', " No longer in the list" );

done_testing();
