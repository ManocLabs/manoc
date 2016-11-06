use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::DHCPSharedSubnet;

ok( request('/dhcpsharedsubnet')->is_success, 'Request should succeed' );
done_testing();
