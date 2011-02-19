#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
eval { use local::lib "$FindBin::Bin/../support" };

use Manoc::App::ArpSniffer;

my $daemon = Manoc::App::ArpSniffer->new_with_options();

my ($command) = @{ $daemon->extra_argv };
defined $command || die "No command specified";

if ( $command eq 'start' ) {
    if ( $daemon->debug ) {
        $daemon->start_pcap_loop();
    }
    else {
        $daemon->start;
    }
}
elsif ( $command eq 'stop' ) {
    $daemon->stop;
}
elsif ( $command eq 'status' ) {
    $daemon->status;
}
elsif ( $command eq 'restart' ) {
    $daemon->restart;
}
else {
    die "Unkwown command $command";
}

warn( $daemon->status_message );
exit( $daemon->exit_code );

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
