#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech = get_mech();

mech_login();

$mech->get_ok( '/building' );
$mech->text_contains( 'Buildings' );

#test accessing create without privileges
$mech->get( '/building/create' );
my $status = $mech->status();
cmp_ok( $status, '==', 200, "Accessing building create page");

$mech->submit_form_ok(
        {
            fields => {
                name        => 'Test',
                description => 'Test',
                notes       => 'Test',
            },
        },
        'Submit create building form',
);
$mech->text_contains("Buildings", "Redirect to the building list page");


done_testing();
