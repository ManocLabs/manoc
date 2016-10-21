use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::Server;

ok( request('/server')->is_success, 'Request should succeed' );
done_testing();
