#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use FindBin;
    require "$FindBin::Bin/lib/inc.pl";
    require "$FindBin::Bin/lib/mechanize.pl";
}

# we DON'T want autologin!
$ENV{MANOC_TEST_AUTOLOGIN} = 0;

$Mech->get_ok( '/auth/login' );
$Mech->text_contains( "Manoc login", "Make sure we are on the login page" );

$Mech->submit_form_ok(
    { 
	fields => {
	    username   => $ENV{MANOC_TEST_USER},
	    password   => $ENV{MANOC_TEST_PASS},
      },
    },
    'Submit login form',
    );
$Mech->text_contains( "User: ". $ENV{MANOC_TEST_USER}, "Check user name in menubar" );
$Mech->follow_link_ok({text => 'Logout'}, "Click on logout");
$Mech->text_contains( "Manoc login", "Back to login page after login" );

# Test redirect: requires /search page!
my $wanted_page = '/search';
my $expected_string = 'Manoc search';


$Mech->max_redirect(0);
$Mech->get( $wanted_page );
my $status = $Mech->status();
ok( ($status >= 300 && $status < 400), "Got redirect when accessing page without auth");
my $location = $Mech->response()->header('Location');
$Mech->get( $location  );
$Mech->text_contains( "Manoc login", "Redirected to the login page" );
$Mech->max_redirect(1);
$Mech->submit_form_ok(
    { 
	fields => {
	    username   => $ENV{MANOC_TEST_USER},
	    password   => $ENV{MANOC_TEST_PASS},
      },
    },
    'Submit login form',
    );
$Mech->text_contains( $expected_string, "Make sure we are redirected to the about page" );

done_testing();
