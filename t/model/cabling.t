use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

ok($schema->init_vlan, "Initialize vlans");

my $lan_segment = $schema->resultset("LanSegment")->search( {} )->first();
ok($lan_segment, "Get default lansegment");

my $device1 = $schema->resultset("Device")->create(
    {
        name        => 'D01',
        mng_address => '10.0.0.1',
        lan_segment => $lan_segment,
    }
);
# get defaults from DB
$device1->discard_changes;
ok($device1, "Created first test device");


my $interface_1_0 = $schema->resultset("DeviceIface")->create({
    device => $device1,
    name   => "port0",
});
$interface_1_0->discard_changes;
ok($interface_1_0, "Created test interface 1.0");

my $interface_1_1 = $schema->resultset("DeviceIface")->create({
    device => $device1,
    name   => "port1",
});
$interface_1_1->discard_changes;
ok($interface_1_1, "Created test interface 1.1");

my $interface_1_2 = $schema->resultset("DeviceIface")->create({
    device => $device1,
    name   => "port2",
});
$interface_1_2->discard_changes;
ok($interface_1_2, "Created test interface 1.22");


my $device2 = $schema->resultset("Device")->create(
    {
        name        => 'D02',
        mng_address => '10.0.0.2',
        lan_segment => $lan_segment,
    }
);
# get defaults from DB
$device2->discard_changes;
ok($device2, "Created second test device");

my $interface_2_0 = $schema->resultset("DeviceIface")->create({
    device => $device2,
    name   => "port0",
});
$interface_2_0->discard_changes;
ok($interface_2_0, "Created test interface 2.0");

my $interface_2_1 = $schema->resultset("DeviceIface")->create({
    device => $device2,
    name   => "port1",
});
$interface_2_1->discard_changes;
ok($interface_2_1, "Created test interface 2.1");

my $device3 = $schema->resultset("Device")->create(
    {
        name        => 'D03',
        mng_address => '10.0.0.3',
        lan_segment => $lan_segment,
    }
);
# get defaults from DB
$device3->discard_changes;
ok($device3, "Created third test device");

my $interface_3_0 = $schema->resultset("DeviceIface")->create({
    device => $device3,
    name   => "port0",
});
$interface_3_0->discard_changes;
ok($interface_3_0, "Created test interface 3.0");


my $serverhw = $schema->resultset("ServerHW")->create({
    ram_memory => '16000',
    cpu_model  => 'E1234',
    vendor     => 'Moon',
    model      => 'ShinyBlade',
});
ok( $serverhw, "Created a server hw asset");

# create a nic type
my $nic_type = $schema->resultset("NICType")->find_or_create(
    {
        name     => 'Eth 100',
    }
);
ok( $nic_type, "Create a test NIC type");


my $hwserver_nic1 = $schema->resultset("ServerHWNIC")->create({
    name     => 'eth0',
    macaddr  => '00:11:22:33:44:55',
    nic_type => $nic_type,
    serverhw => $serverhw,
} );
$hwserver_nic1->discard_changes;
ok($hwserver_nic1,  "Created test server nic");

### Ready to test!

#
#   +------------------------+
#   |        Device 1        |
#   +------------------------+
#     0 |  | 1        | 2
#       |  |          |
#     0 |  | 1        | nic
#   +----------+   +--------+
#   | Device 2 |   | Server |
#   +----------+   +--------+

my $device1_cabling_count = 0;

eval {
    $schema->resultset("CablingMatrix")->create(
        {
            interface1 => $interface_1_0,
         } );
};
ok( $@, "interface2 or hwserver_nic should be set" );

eval {
    $schema->resultset("CablingMatrix")->create(
        {
            interface1      => $interface_1_0,
            interface2      => $interface_2_0,
            hwserver_nic    => $hwserver_nic1
         } );
};
ok( $@, "cannot set both hwserver_nic and device2" );

# test via DeviceIface
$interface_1_0->add_cabling_to_interface($interface_2_0);
ok(defined( $interface_2_0->cabling ), "Updated cabling relationsship");

is($interface_1_0->cabling->device1->id, $device1->id, "Check device_id interface1");
is($interface_1_0->cabling->interface2->id, $interface_2_0->id, "Check dst interface id");
is($interface_2_0->cabling->device1->id, $device2->id, "Check device_id interface2");

cmp_ok( $device1->cablings->count, '==', 1, "Device1 has 1 cabling" );
cmp_ok( $device2->cablings->count, '==', 1, "Device2 has 1 cabling" );


eval {
    $interface_1_0->add_cabling_to_interface( $interface_3_0  );
};
ok( $@, "Cannot reuse same port twice (->interface)" );

eval {
    $interface_1_0->add_cabling_to_nic( $hwserver_nic1 );
};
ok( $@, "Cannot reuse same port twice (->nic)" );

eval {
    $interface_2_0->add_cabling_to_interface( $interface_3_0  );
};
ok( $@, "Cannot reuse same port twice (destitantion interface)" );

ok(
    $interface_1_1->add_cabling_to_interface( $interface_2_1 ),
    "Connected device1/port1 => device2/port1"
    );
$device1_cabling_count++;

ok(
    $interface_1_2->add_cabling_to_nic($hwserver_nic1),
    "Connected device1/port4 => hwserver_nic1"
 );
$device1_cabling_count++;

cmp_ok( $device2->cablings->count, '==', $device1_cabling_count, "Check cablings count" );

my $cabling = $interface_1_0->cabling;
eval {
    $cabling->interface2($interface_1_0);
    $cabling->update;
};
ok( $@, "Column interface2 cannot be changed");
$cabling->discard_changes;

eval {
    $cabling->nic(undef);
    $cabling->update;
};
ok( $@, "Column nic cannot be changed");
$cabling->discard_changes;


ok ( $interface_1_0->remove_cabling, "Remove cabling dev0/port0 <-> dev1/port0" );
$interface_1_0->discard_changes;
$interface_2_0->discard_changes;
is ( $interface_1_0->cabling, undef, "Check dev0/port0 is no longer connected " );
is ( $interface_2_0->cabling, undef, "Check dev1/port0 is no longer connected " );


done_testing;
