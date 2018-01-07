package App::Manoc::Support;

use strict;
use warnings;

##VERSION

use FindBin;

BEGIN {
    local $^W = 0;

    my @paths = ( "$FindBin::Bin/../perl5", "$FindBin::Bin/../../perl5", "/opt/manoc/perl5" );

    foreach my $support_dir (@paths) {

        next unless -d $support_dir;

        eval "use local::lib '$support_dir'";
        unless ($@) {
            delete $INC{"File/Path.pm"};
            require "File/Path.pm";    ## no critic
        }

        last;
    }
}

1;
