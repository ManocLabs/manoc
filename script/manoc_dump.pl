#!/usr/bin/perl -w
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use App::Manoc::Support;

package main;
use App::Manoc::DataDumper::Script;

my $app = App::Manoc::DataDumper::Script->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
