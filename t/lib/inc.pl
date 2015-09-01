use strict;
use warnings;

# chdir to the dir the test directory and set config file
BEGIN {
    use FindBin     qw/$Bin/;

    # test script dir
    chdir $Bin if -d $Bin;

    # Include our application dir and our own lib dir
    use lib "$Bin/../lib";
    use lib "$Bin/lib";

    $ENV{CATALYST_CONFIG} = "$Bin/lib/manoc_test.conf";
    $ENV{MANOC_NO_CSRFBLOCK} = 1;
    $ENV{MANOC_NO_AUTH} //= 0;
}

use Catalyst::Test 'Manoc';
use HTTP::Request::Common;
1;
