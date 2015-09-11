use strict;
use warnings;
use Test::More;

use Manoc::Utils qw(str2seconds);

BEGIN {

    use_ok 'Manoc::Search::Item';
    use_ok 'Manoc::Search::Item::Group';
    use_ok 'Manoc::Search::Item::IpAddr';
    use_ok 'Manoc::Search::Item::MacAddr';
    use_ok 'Manoc::Search::Item::IPNetwork';
    use_ok 'Manoc::Search::Item::IPRange';
    use_ok 'Manoc::Search::Item::Rack';
    use_ok 'Manoc::Search::Item::Device';	
    use_ok 'Manoc::Search::Item::Building';

    use_ok 'Manoc::Search::Engine';
    use_ok 'Manoc::Search::Query';

    use_ok 'Manoc::Search';
}

#my $engine;
#ok( $engine = Manoc::Search::Engine->new() );

my $item;
ok( $item = Manoc::Search::Item::IpAddr->new( { match => '1.1.1.1' } ) );
ok( $item = Manoc::Search::Item::MacAddr->new( { match => '1.1.1.1' } ) );

done_testing();
