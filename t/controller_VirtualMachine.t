use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::VirtualMachine;

ok( request('/virtualmachine')->is_success, 'Request should succeed' );
done_testing();
