use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::VirtualInfr;

ok( request('/virtualinfr')->is_success, 'Request should succeed' );
done_testing();
