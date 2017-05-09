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

# visit (empty) rack list
$mech->get_ok('/rack');
$mech->title_is('Manoc - Racks');

# building used for test rack
my $building = $schema->resultset("Building")->create(
    {
        name        => 'B01',
        description => 'Test building',
    }
);

like( $mech->find_link( text => 'Add' )->url,
    qr|/rack/create$|, "Add link points to rack/create" );

# continue testing even if Add link is broken
$mech->get_ok( '/rack/create', "Create rack page" );
$mech->submit_form_ok(
    {
        form_id => 'form-rack',
        fields  => {
            'form-rack.building' => $building->id
        },
    },
    "Submit uncomplete form",
);
$mech->text_contains('Name field is required');
$mech->text_contains('Floor field is required');
$mech->text_contains('Room field is required');

# try with a correct form
$mech->submit_form_ok(
    {
        form_id => 'form-rack',
        fields  => {
            'form-rack.name'     => 'Rack01',
            'form-rack.floor'    => 1,
            'form-rack.room'     => 'L320',
            'form-rack.building' => $building->id
        },
    },
    "Create rack in building",
);
$mech->title_is( 'Manoc - Rack Rack01', 'Rack page' );

$mech->get('/rack');
$mech->text_contains( 'Rack01', "New rack in the list" );
$mech->follow_link_ok( { text => 'Rack01' }, "View rack page" );
$mech->title_is('Manoc - Rack Rack01');

ok( $mech->find_link( text => 'Add device' ), "Add device link" );
ok( $mech->find_link( text => 'Add server' ), "Add server link" );

$mech->follow_link_ok( { text => 'Delete' }, "Follow delete link" );
# first form is search box
$mech->submit_form_ok( { form_number => 2 } );

$mech->title_is( 'Manoc - Racks', "Back to rack list" );
$mech->content_lacks( 'Rack01', "Rack is no longer in the list" );

$mech->get_ok( '/rack/create?building=' . $building->id,
    "Rack create page with default building" );
$mech->form_id('form-rack');
cmp_ok( $mech->value('form-rack.building'), 'eq', $building->id, "Preset building id found" );

done_testing();
