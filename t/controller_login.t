#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;
use ManocTest::Schema;

init_manoctest;

my $mech = get_mech();

mech_login();
$mech->follow_link_ok({text => 'Logout'}, "Click on logout");
$mech->text_contains( "Manoc login", "Back to login page after login" );

# Test redirect: requires /search page!
my $wanted_page = '/search';
my $expected_string = 'Manoc search';

$mech->max_redirect(0);
$mech->get( $wanted_page );
my $status = $mech->status();
ok( ($status >= 300 && $status < 400), "Got redirect when accessing page without auth");
my $location = $mech->response()->header('Location');
$mech->get( $location  );
$mech->text_contains( "Manoc login", "Redirected to the login page" );
$mech->max_redirect(1);
$mech->submit_form_ok(
    {
	fields => {
	    username   => $ManocTest::ADMIN_USER,
	    password   => $ManocTest::ADMIN_PASS
      },
    },
    'Submit login form',
    );
$mech->text_contains( $expected_string, "Make sure we are redirected to the about page" );

done_testing();
