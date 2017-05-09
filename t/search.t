use strict;
use warnings;
use Test::More;

use App::Manoc::Utils::Datetime qw(str2seconds);

BEGIN {

    use_ok 'App::Manoc::Search::Item';
    use_ok 'App::Manoc::Search::Item::Group';

    use_ok 'App::Manoc::Search::Item::IpAddr';
    use_ok 'App::Manoc::Search::Item::MacAddr';
    use_ok 'App::Manoc::Search::Item::IPNetwork';
    use_ok 'App::Manoc::Search::Item::IPRange';
    use_ok 'App::Manoc::Search::Item::Rack';
    use_ok 'App::Manoc::Search::Item::Device';
    use_ok 'App::Manoc::Search::Item::Building';
    use_ok 'App::Manoc::Search::Item::Server';
    use_ok 'App::Manoc::Search::Item::HWAsset';
    use_ok 'App::Manoc::Search::Item::VirtualMachine';

    use_ok 'App::Manoc::Search::Engine';
    use_ok 'App::Manoc::Search::Query';

    use_ok 'App::Manoc::Search';
}

#my $engine;
#ok( $engine = App::Manoc::Search::Engine->new() );

my $item;
ok( $item = App::Manoc::Search::Item::IpAddr->new( { match => '1.1.1.1' } ) );
ok( $item = App::Manoc::Search::Item::MacAddr->new( { match => '1.1.1.1' } ) );

done_testing();
