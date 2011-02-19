use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Manoc' }
BEGIN { use_ok 'Manoc::Controller::Error' }

ok( request('/error')->is_success, 'Request should succeed' );
done_testing();
