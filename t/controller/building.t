#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech = get_mech();

mech_login();

$mech->get_ok('/building');
$mech->title_is('Manoc - Buildings');

#test accessing create without privileges
$mech->get('/building/create');
my $status = $mech->status();
cmp_ok( $status, '==', 200, "Accessing building create page" );

$mech->submit_form_ok(
    {
        form_id => 'form-building',
        fields  => {
            'form-building.name'        => 'B01',
            'form-building.description' => 'Test',
            'form-building.notes'       => 'Test',
        },
    },
    'Submit create building form',
);
$mech->title_is( "Manoc - Building B01", "Redirect to the building page" );

done_testing();
