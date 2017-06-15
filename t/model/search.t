use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

BEGIN {
    use_ok 'App::Manoc::DB::Search';
}

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

my $searcher = App::Manoc::DB::Search->new( schema => $schema );
ok( $searcher, "Searcher creaed" );

done_testing();
