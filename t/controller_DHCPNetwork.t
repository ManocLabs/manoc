use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::DHCPNetwork;

ok( request('/dhcpnetwork')->is_success, 'Request should succeed' );
done_testing();
