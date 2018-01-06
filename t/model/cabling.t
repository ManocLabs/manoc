use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

$schema->init_vlan;
my $lan_segment = $schema->resultset("LanSegment")->search( {} )->first();
my $device1 = $schema->resultset("Device")->create(
    {
        name        => 'D01',
        mng_address => '10.0.0.1',
        lan_segment => $lan_segment,
    }
);
# get defaults from DB
$device1->discard_changes;
my $device2 = $schema->resultset("Device")->create(
    {
        name        => 'D02',
        mng_address => '10.0.0.2',
        lan_segment => $lan_segment,
    }
);
# get defaults from DB
$device2->discard_changes;
my $device3 = $schema->resultset("Device")->create(
    {
        name        => 'D03',
        mng_address => '10.0.0.3',
        lan_segment => $lan_segment,
    }
);
# get defaults from DB
$device3->discard_changes;


my $server = $schema->resultset("ServerHW")->create({
    ram_memory => '16000',
    cpu_model  => 'E1234',
    vendor     => 'Moon',
    model      => 'ShinyBlade',
});
my $server_nic1 = $schema->resultset("HWServerNIC")->create({
    name     => 'eth0',
    macaddr  => '00:11:22:33:44:55',
    serverhw => $server,
}  );

### Ready to test!

my $cabling;
my $device1_cabling_count = 0;

eval {
    $schema->resultset("CablingMatrix")->create(
        {
            device1 => $device1,
            interface1 => 'port0',
         } );
};
ok( $@, "device2 or server_nic should be set" );

eval {
    $schema->resultset("CablingMatrix")->create(
        {
            device1 => $device1,
            interface1 => 'port0',
            device2 => $device2,
         } );
};
ok( $@, "device2 requires interface2" );


eval {
    $schema->resultset("CablingMatrix")->create(
        {
            device1         => $device1,
            interface1      => 'port0',
            device2         => $device2,
            server_nic      => $server_nic1
         } );
};
ok( $@, "cannot set both server_nic and device2" );


$cabling = $schema->resultset("CablingMatrix")->create(
    {
        device1         => $device1,
        interface1      => 'port0',
        device2         => $device2,
        interface2      => 'port0'
    });
ok($cabling, "Connected device1/port0 => device2/port0");
$device1_cabling_count++;

cmp_ok( $device1->cablings->count, '==', 1, "Device1 has 1 cabling" );
cmp_ok( $device1->cablings->count, '==', 1, "Device2 has 1 cabling" );

eval {
    $schema->resultset("CablingMatrix")->create(
        {
            device1     => $device1,
            interface1  => 'port0',
            device2     => $device3,
            interface2  => 'port0'
         } );
};
ok( $@, "Cannot reuse same port twice (dev1/interface1)" );

eval {
    $schema->resultset("CablingMatrix")->create(
        {
            device1     => $device2,
            interface1  => 'port0',
            device2     => $device3,
            interface2  => 'port0'
         } );
};
ok( $@, "Cannot reuse same port twice (dev2/interface2)" );


eval {
    $schema->resultset("CablingMatrix")->create(
        {
            device1     => $device1,
            interface1  => 'port0',
            server_nic  => $server_nic1
         } );
};
ok( $@, "Cannot reuse same port twice (dev1/interface1)" );


$cabling = $schema->resultset("CablingMatrix")->create(
    {
        device1     => $device1,
        interface1  => 'port1',
        device2     => $device2,
        interface2  => 'port1'
    });
ok($cabling, "Connected device1/port1 => device2/port2");
$device1_cabling_count++;

$cabling = $schema->resultset("CablingMatrix")->create(
    {
        device1     => $device1,
        interface1  => 'port3',
        device2     => $device3,
        interface2  => 'port0'
    });
ok($cabling, "Connected device1/port3 => device3/port0");
$device1_cabling_count++;

$cabling = $schema->resultset("CablingMatrix")->create(
    {
        device1     => $device1,
        interface1  => 'port4',
        server_nic  => $server_nic1,
    });
ok($cabling, "Connected device1/port4 => server_nic1");
$device1_cabling_count++;

cmp_ok( $device1->cablings->count, '==', $device1_cabling_count, "Device has 1 cabling" );

eval {
    $cabling = $schema->resultset("CablingMatrix")->create(
        {
            device1         => $device1,
            interface1      => 'port4',
            server_nic      => $server_nic1
        });
};
ok( $@,, "Cannot connect same server_nic twice");

eval {
    $cabling->interface2("ae1");
    $cabling->update;
};
ok( $@, "Column interface2 cannot be changed");


eval {
    $cabling->device2($device3);
    $cabling->update;
};
ok( $@, "Column device2 cannot be changed");

eval {
    $cabling->nic(undef);
    $cabling->update;
};
ok( $@, "Column nic cannot be changed");


done_testing;
