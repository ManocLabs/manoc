use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Manoc';
use Manoc::Controller::HWAsset;

ok( request('/hwasset')->is_success, 'Request should succeed' );
done_testing();
