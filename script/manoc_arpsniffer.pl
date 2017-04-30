#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use App::Manoc::Support;

use App::Manoc::ArpSniffer;

my $app = App::Manoc::ArpSniffer->new_with_options();
$app->run;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
