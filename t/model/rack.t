#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

# building used for test
my $building = $schema->resultset("Building")->create(
    {
        name        => 'B01',
        description => 'Test building',
    }
    ) or
    BAIL_OUT "Can't create test building";

my $rack;
eval { $rack = $schema->resultset("Rack")->create( {} ); };
ok( $@, "name is required" );

$rack = $schema->resultset("Rack")->create(
    {
        name     => 'W02',
        building => $building,
        room     => 'L01',
        floor    => '0'
    }
);
ok( $rack, "Create rack in building" );

my $hwasset = $schema->resultset("HWAsset")->create(
    {
        type      => App::Manoc::DB::Result::HWAsset->TYPE_DEVICE,
        vendor    => 'IQ',
        model     => 'MegaPort 48',
        serial    => 'TestHR01',
        inventory => 'Inv001',
    }
);
$hwasset->move_to_rack($rack);
$hwasset->update;
ok( $rack->hwassets->count, "Asset in rack" );

$schema->init_vlan;
my $lan_segment = $schema->resultset("LanSegment")->search( {} )->first();
my $device = $schema->resultset("Device")->create(
    {
        name        => "D01",
        mng_address => "1.1.1.1",
        rack        => $rack,
        lan_segment => $lan_segment
    }
);
ok( $rack->devices->count, "Device in rack" );

done_testing;
