use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

my $device;
eval { $device = $schema->resultset("Device")->create( { name => 'test' } ); };
ok( $@, "mng_address is required" );

$device = $schema->resultset("Device")->create(
    {
        name        => 'D01',
        mng_address => '10.0.0.1',
    }
);
ok( $device, "Create device" );

# get defaults from DB
$device->discard_changes;

cmp_ok( ref( $device->mng_address ),
    'eq', 'App::Manoc::IPAddress::IPv4', "Check mng_address is a App::Manoc::IPAddress::IPv4" );

ok( !$device->decommissioned, "New devices are marked as not decommisioned" );

ok( !defined( $device->get_mng_url ), "Default mng url is null" );

my $fmt = $schema->resultset('MngUrlFormat')->update_or_create(
    {
        name   => 'telnet',
        format => 'telnet:%h',
    }
);
$device->mng_url_format($fmt);
cmp_ok( $device->get_mng_url, "eq", "telnet:10.0.0.1", "Check mng URL" );

ok( !defined( $device->get_config_date ), "No configuration date by default" );
$device->update_config( "Config 1", 1000 );
cmp_ok( $device->get_config_date, '==', 1000, "Check configuration date" );
$device->update_config( "Config 2", 2000 );
cmp_ok( $device->get_config_date,     '==', 2000,       "Check updated configuration date" );
cmp_ok( $device->config->prev_config, 'eq', 'Config 1', "Check previous config" );
cmp_ok( $device->config->config,      'eq', 'Config 2', "Check current config" );
$device->update_config( "Config 3", 3000 );
cmp_ok( $device->config->prev_config, 'eq', 'Config 2', "Check config rotation" );

$device->create_related(
    'netwalker_info' => {
        manifold => 'TestManifold',
    }
);
ok( $device->netwalker_info, "Netwalker info" );

$device->decommission();
$device->discard_changes();
ok( $device->decommission_ts,            "Decommissioned device has a decommission TS" );
ok( !defined( $device->netwalker_info ), "No netwalker info for decommissioned device" );

eval { $schema->resultset("Device")->create( { name => 'D02', mng_address => '10.0.0.1', } ); };
ok( $@, "Duplicate address not allowed even for decommissione devices" );

done_testing;
