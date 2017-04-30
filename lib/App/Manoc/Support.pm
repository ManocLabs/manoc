# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package App::Manoc::Support;

use FindBin;

BEGIN {
    local $^W = 0;
    my $support_dir = "$FindBin::Bin/../support/";

    if ( -d $support_dir ) {
        eval "use local::lib '$support_dir'";
        unless ($@) {
            delete $INC{"File/Path.pm"};
            require "File/Path.pm";
        }
    }
}

1;
