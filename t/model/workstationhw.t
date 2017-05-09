use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $model      = "DeskCompanion";
my $vendor     = "HAL";
my $ram_memory = '4096';
my $cpu_model  = 'i8000';

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

my $rs = $schema->resultset("WorkstationHW");
ok( $rs, 'Resultset' );

my %fields = (
    ram_memory => $ram_memory,
    cpu_model  => $cpu_model,
    vendor     => $vendor,
    model      => $model,
);

foreach my $attr ( keys %fields ) {
    my %test_fields = %fields;
    delete $test_fields{$attr};
    eval { my $hw = $rs->create( \%test_fields ); };
    ok( $@, "$attr is required" );
}

# add optional fields
$fields{display}          = "integrated 15";
$fields{ethernet_macaddr} = "aa:bb:cc:11:22:33";
$fields{wireless_macaddr} = "aa:bb:cc:11:22:44";
$fields{storage1_size}    = 200;

my $hw = $rs->create( \%fields );
ok( $hw,         "Create a WorkstationHW using create" );
ok( $hw->delete, "Delete" );

ok( $hw = $rs->new_result( {} ), "New result with empty args" );
foreach my $attr ( keys %fields ) {
    ok( $hw->$attr( $fields{$attr} ), "set column $attr" );
}
ok( $hw->insert(), "Insert" );
$hw->discard_changes();

ok( $hw->hwasset,            "hwasset is not null" );
ok( $hw->is_in_warehouse,    "default location is warehouse" );
ok( !$hw->is_decommissioned, "default not decommissioned" );

my $building = $schema->resultset("Building")->create(
    {
        name        => 'B01',
        description => 'Test'
    }
);

$hw->move_to_room( $building, "1", "R01" );
ok( !$hw->is_decommissioned, "if in room not decommissioned" );
ok( !$hw->is_in_warehouse,   "if in room not in warehouse" );
is( $hw->hwasset->display_location, "B01 (Test) - 1 - R01", "Display location room" );

$hw->move_to_warehouse();
ok( $hw->is_in_warehouse,    "move to warehouse" );
ok( !$hw->is_decommissioned, "if in w/h not decommissioned" );
is( $hw->hwasset->display_location, "Warehouse", "Display location Warehouse" );

$hw->decommission();
ok( $hw->is_decommissioned, "decommissioned" );
ok( !$hw->is_in_warehouse,  "if decommissioned not in warehouse" );
is( $hw->hwasset->display_location, "Decommissioned", "Display location decommissioned" );

my $inventory = "M0001";
$hw->inventory($inventory);
is( $hw->label, "$inventory ($vendor - $model)", "label" );

$hw->delete;

# force scalar context
my $r = $rs->populate(
    [
        {
            ram_memory  => $ram_memory,
            cpu_model   => $cpu_model,
            vendor      => $vendor,
            model       => $model,
            serial      => "Test01",
            workstation => {
                hostname => "TestWorkstation01",
            }
        },

    ]
);

$schema->resultset("HWAsset")->create(
    {
        type   => App::Manoc::DB::Result::HWAsset->TYPE_DEVICE,
        vendor => 'DeviceVendor',
        model  => 'MegaPort 48',
        serial => 'Test04',
    }
);

# force scalar context
$r = $rs->populate(
    [
        {
            ram_memory => $ram_memory,
            cpu_model  => $cpu_model,
            vendor     => $vendor,
            model      => $model,
            serial     => "Test02",
            location   => App::Manoc::DB::Result::HWAsset->LOCATION_DECOMMISSIONED,
        },
        {
            ram_memory => $ram_memory,
            cpu_model  => $cpu_model,
            vendor     => $vendor,
            model      => $model,
            serial     => "Test03",
        },
    ]
);

my $unused_rs = $rs->unused;
is( $unused_rs->count,        1,        "No extra result in unused query" );
is( $unused_rs->next->serial, 'Test03', "Unused workstation is the right one" );
done_testing;
