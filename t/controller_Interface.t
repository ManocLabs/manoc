use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Manoc' }
BEGIN { use_ok 'Manoc::Controller::Interface' }

ok( request('/interface')->is_success, 'Request should succeed' );
done_testing();
