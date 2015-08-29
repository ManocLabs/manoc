use strict;
use warnings;
use Test::More;

BEGIN {
    use FindBin;
    require "$FindBin::Bin/lib/inc.pl";
    require "$FindBin::Bin/lib/mechanize.pl";
}


$Mech->get_ok( 'http://localhost/login' );
done_testing();
