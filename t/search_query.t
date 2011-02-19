use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Utils qw(str2seconds);

BEGIN { use_ok 'Manoc::Search::Query' }

my ( $q, $s );

ok( $q = Manoc::Search::Query->new( { search_string => 'test' } ), 'Object creation' );

$q = Manoc::Search::Query->new( { search_string => 'word' } );
$q->parse;
ok( @{ $q->words() } == 1, 'Tokenizer one word' );

$s = 'more than two words';
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse;
ok( @{ $q->words() } == 4, 'Tokenizer four words' );

$s = 'here "the words" "have been quoted" by "me"';
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse;
ok( @{ $q->words() } == 5, 'Tokenizer quotes' );

$s = 'rack 23';
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse;
ok( @{ $q->words() } == 1 && $q->words()->[0] eq '23' && $q->query_type eq 'rack',
    'Rack shortcut' );

$s = 'building "central palace"';
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse;
ok(
    @{ $q->words() } == 1 &&
        $q->words()->[0] eq 'central palace' &&
        $q->query_type   eq 'building',
    'Building shortcut'
);

$s = "limit:5d and complex query";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok( @{ $q->words() } == 3 && $q->limit == str2seconds('5d'), 'Tokenizer limit keyword 1' );

$s = "keyword limit:5d inside query";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok( @{ $q->words() } == 3 && $q->limit == str2seconds('5d'), 'Tokenizer limit keyword 2' );

$s = "keyword limit 5d inside query";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok( @{ $q->words() } == 3 && $q->limit == str2seconds('5d'), 'Tokenizer limit keyword 3' );

$s = "a 1.2.30.255/3 subnet";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 2 &&
            $q->subnet eq '1.2.30.255' &&
            $q->prefix == '3' &&
            $q->query_type eq 'subnet'
    ),
    'Tokenizer subnet 1'
);

$s = "1.2.30.255/32 limit 5d";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 0 &&
            $q->subnet eq '1.2.30.255' &&
            $q->prefix == '32' &&
            $q->query_type eq 'subnet' &&
            $q->limit == str2seconds('5d')
    ),
    'Tokenizer subnet with limit keyword'
);

$s = "10.1.2.234";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->query_word eq '10.1.2.234' &&
            $q->query_type eq 'ipaddr' &&
            $q->match      eq 'exact'
    ),
    'Guessing IPv4 address'
);

$s = "10.1.2.";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->query_word eq '10.1.2.' &&
            $q->query_type eq 'ipaddr' &&
            $q->match      eq 'begin'
    ),
    'Guessing partial IPv4 address'
);

$s = "00:50:56:C0:00:08";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->words->[0] eq '00:50:56:c0:00:08' &&
            $q->query_type eq 'macaddr' &&
            $q->match      eq 'exact'
    ),
    'Guessing mac address'
);

$s = "00-50-56-C0-00-08";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->words->[0] eq '00:50:56:c0:00:08' &&
            $q->query_type eq 'macaddr' &&
            $q->match      eq 'exact'
    ),
    'Guessing mac address Windows notation'
);

$s = "0050.56C0.0008";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->words->[0] eq '00:50:56:c0:00:08' &&
            $q->query_type eq 'macaddr' &&
            $q->match      eq 'exact'
    ),
    'Guessing mac address Cisco notation'
);

$s = "0a:b8:";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->query_word eq '0a:b8:' &&
            $q->query_type eq 'macaddr' &&
            $q->match      eq 'begin'
    ),
    'Guessing partial mac address (begin)'
);

$s = ":00:08";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->query_word eq ':00:08' &&
            $q->query_type eq 'macaddr' &&
            $q->match      eq 'end'
    ),
    'Guessing mac address (end)'
);

$s = "subnet 172.16.100.0";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->query_word eq '172.16.100.0' &&
            $q->query_type eq 'subnet' &&
            $q->match      eq 'exact'
    ),
    'Guessing subnet w/out prefix'
);

$s = "23 type:rack";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->query_word eq '23' &&
            $q->query_type eq 'rack' &&
            $q->match      eq 'partial'
    ),
    'Guessing rack query with specified type'
);

$s = "device \"172.18.19.4\"";
$q = Manoc::Search::Query->new( { search_string => $s } );
$q->parse();
ok(
    (
        @{ $q->words() } == 1 &&
            $q->query_word eq '172.18.19.4' &&
            $q->query_type eq 'device' &&
            $q->match      eq 'exact'
    ),
    'Guessing quoted string'
);

done_testing();
