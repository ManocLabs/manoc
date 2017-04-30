package App::Manoc::Support;

use strict;
use warnings;

##VERSION

use FindBin;

BEGIN {
    local $^W = 0;
    my $support_dir = "$FindBin::Bin/../support/";

    if ( -d $support_dir ) {
        eval "use local::lib '$support_dir'";
        unless ($@) {
            delete $INC{"File/Path.pm"};
            require "File/Path.pm";    ## no critic
        }
    }
}

1;
