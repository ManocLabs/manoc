use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok($schema, "Create schema");

my $rs = $schema->resultset("ServerHW");
ok($rs, 'Resultset');

my %fields = (
            ram_memory => '16000',
            cpu_model  => 'E1234',
            vendor     => 'Moon',
            model      => 'ShinyBlade',
            );

foreach my $attr (keys %fields) {
    my %test_fields = %fields;
    delete $test_fields{$attr};
    eval {
         my $hw = $rs->create(\%test_fields);
     };
    ok($@, "$attr is required");
};

my $hw = $rs->create(\%fields);
ok($hw, "Create a ServerHW using create");
ok($hw->delete, "Delete");

ok($hw = $rs->new_result({}), "New result with empty args");
foreach my $attr (keys %fields) {
    ok($hw->$attr($fields{$attr}), "set column $attr");
}
ok($hw->insert(), "Insert");
$hw->discard_changes();

ok($hw->hwasset, "hwasset is not null");
ok($hw->is_in_warehouse, "default location is warehouse");
ok(!$hw->is_decommissioned, "default not decommissioned");

my $building = $schema->resultset("Building")->create({
    name => 'B01',
    description => 'Test'
});
my $rack = $schema->resultset("Rack")->create({
    name => 'R01',
    floor => 1,
    room => '00',
    building => $building,
});
$hw->move_to_rack($rack);
ok($hw->is_in_rack, "Move to rack");
ok(!$hw->is_decommissioned, "if in rack not decommissioned");
ok(!$hw->is_in_warehouse, "if in rack not in warehouse");
is($hw->hwasset->display_location, "Rack R01 (B01)", "Display location rack");


$hw->move_to_room($building, "1", "R01");
ok(!$hw->is_decommissioned, "if in room not decommissioned");
ok(!$hw->is_in_warehouse, "if in room not in warehouse");
ok(!$hw->is_in_rack, "if in room not in rack");
is($hw->hwasset->display_location, "B01 (Test) - 1 - R01", "Display location room");


$hw->move_to_warehouse();
ok($hw->is_in_warehouse, "move to warehouse");
ok(!$hw->is_decommissioned, "if in w/h not decommissioned");
ok(!$hw->is_in_rack, "if in room not in rack");
is($hw->hwasset->display_location, "Warehouse", "Display location Warehouse");

$hw->decommission();
ok($hw->is_decommissioned, "decommissioned");
ok(!$hw->is_in_warehouse, "if decommissioned not in warehouse");
ok(!$hw->is_in_rack, "if decommissioned not in rack");
is($hw->hwasset->display_location, "Decommissioned", "Display location decommissioned");


$hw->inventory("M0001");
is($hw->label, 'M0001 (Moon - ShinyBlade)', "label");


done_testing;
