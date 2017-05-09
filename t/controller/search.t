#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 't/lib';

use ManocTest;

init_manoctest();

my $mech = get_mech();

mech_login();

$mech->get_ok('/search');
$mech->text_contains('Search');

done_testing();
