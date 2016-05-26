use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::DHCPServer;

ok( request('/dhcpserver')->is_success, 'Request should succeed' );
done_testing();
