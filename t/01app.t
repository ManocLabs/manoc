#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use lib qw 't/lib';

use_ok 'Catalyst::Test', 'App::Manoc';

done_testing();
