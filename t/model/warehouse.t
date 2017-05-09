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

{
    my $warehouse;
    eval { $warehouse = $schema->resultset("Warehouse")->create(); };
    ok( $@, "name is required" );

    $warehouse = $schema->resultset("Warehouse")->create( { name => 'W01' } );
    ok( $warehouse,         "Create warehouse" );
    ok( $warehouse->delete, "Delete warehouse" );
}

{
    my $warehouse = $schema->resultset("Warehouse")->create(
        {
            name     => 'W02',
            building => $building,
            room     => 'L01',
            floor    => '0'
        }
    );
    ok( $warehouse, "Create warehouse in building" );

    my $hwasset = $schema->resultset("HWAsset")->create(
        {
            type      => App::Manoc::DB::Result::HWAsset->TYPE_DEVICE,
            vendor    => 'IQ',
            model     => 'MegaPort 48',
            serial    => 'TestHW01',
            inventory => 'Inv001',
        }
    );
    $hwasset->move_to_warehouse($warehouse);
    $hwasset->update;
    ok( $warehouse->hwassets->count, "Asset in warehouse" );

}

done_testing;
