use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok($schema, "Create schema");

my $wks;


$wks = $schema->resultset("Workstation")->create({
       hostname               => 'W01',
       ethernet_static_ipaddr => '10.0.0.1',
       wireless_static_ipaddr => '10.0.0.2',
       });
ok($wks, "Create workstation");

# get defaults from DB
$wks->discard_changes;

cmp_ok(ref($wks->ethernet_static_ipaddr), 'eq', 'App::Manoc::IPAddress::IPv4',
       "Check ethernet address is a App::Manoc::IPAddress::IPv4" );

cmp_ok(ref($wks->wireless_static_ipaddr), 'eq', 'App::Manoc::IPAddress::IPv4',
       "Check wireless address is a App::Manoc::IPAddress::IPv4" );

ok(!$wks->decommissioned, "New devices are marked as not decommisioned");

$wks->decommission();
$wks->discard_changes();
ok($wks->decommission_ts, "Decommissioned device has a decommission TS");

eval {
    $schema->resultset("Workstation")->create({
       hostname        => 'W01',
   });
};
ok($@, "Duplicate name not allowed even for decommissione devices");

ok($wks->restore, "Restore workstation");



done_testing;
