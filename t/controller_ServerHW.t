use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::ServerHW;

ok( request('/serverhw')->is_success, 'Request should succeed' );
done_testing();
