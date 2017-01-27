#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use FindBin;
    require "$FindBin::Bin/lib/inc.pl";
    require "$FindBin::Bin/lib/mechanize.pl";
}

mech_login();

$Mech->get_ok( '/building' );
$Mech->text_contains( 'Buildings' );

#test accessing create without privileges
$Mech->get( '/building/create' );
my $status = $Mech->status();
cmp_ok( $status, '==', 200, "Accessing building create page");

$Mech->submit_form_ok(
        {
            fields => {
                name       => 'Test',
		description=> 'Test',
                notes      => 'Test',
            },
        },
        'Submit create building form',
);
$Mech->text_contains("Buildings", "Redirect to the building list page");






done_testing();
