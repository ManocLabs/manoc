use strict;
use warnings;
use Test::More;

use lib "t/lib";

use_ok 'App::Manoc::DB';
use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

ok( $schema->init_admin,          "Init admin" );
ok( $schema->init_roles,          "Init roles" );
ok( $schema->init_ipnetwork,      "Init IP networks" );
ok( $schema->init_vlan,           "Init VLAN" );
ok( $schema->init_management_url, "Init mng URLs" );

done_testing;
