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

$Mech->get_ok( '/search' );
$Mech->text_contains( 'Search' );

done_testing();
