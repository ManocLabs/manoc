use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::DHCPSubnet;

ok( request('/dhcpsubnet')->is_success, 'Request should succeed' );
done_testing();
