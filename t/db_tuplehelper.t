use strict;
use warnings;
use Test::More;

BEGIN {
    use FindBin;
    require "$FindBin::Bin/lib/inc.pl";

    use Manoc::IPAddress::IPv4;
}

BEGIN {
    use_ok 'ManocTest::Schema';
}


my $schema = ManocTest::Schema->connect();
ok($schema, "Create schema");

# use ARP to check archiving features
{
    my $arp_rs = $schema->resultset('Arp');

    $arp_rs->delete;

    my %tuple1 = (
	ipaddr	=> Manoc::IPAddress::IPv4->new('1.1.1.1')->padded,
	macaddr	=> '00:11:22:33:44:55',
	vlan	=> 1,
    );

    ok( $arp_rs->register_tuple(%tuple1, timestamp => 1 ), "ARP register tuple");
    ok( $arp_rs->search(\%tuple1)->count == 1, "ARP tuple added");

    $arp_rs->register_tuple(
	%tuple1,
	timestamp   => 100,
    );

    ok( $arp_rs->search(\%tuple1)->count == 1, "Refresh ARP tuple");
    ok( $arp_rs->search(\%tuple1)->get_column('lastseen')->max() == 100, "Refreshed ARP tuple has new timestamp");

    ok( $arp_rs->archive(), "Archive entry");

    ok( $arp_rs->search(\%tuple1)->single->archived == 1, "Check archived tuple");

    $arp_rs->register_tuple(
	%tuple1,
    );
    ok( $arp_rs->search(\%tuple1)->count == 2, "New ARP tuple");
}

# check if MAT support archiving
{
    my $mat_rs = $schema->resultset('Mat');

    $mat_rs->delete;
    my %tuple1 = (
	device_id	=> 1,
	macaddr	=> '00:11:22:33:44:55',
	interface => 'test0.1',
	vlan	=> 1,
    );

    ok( $mat_rs->register_tuple(%tuple1, timestamp => 1 ), "MAT register tuple");
    ok( $mat_rs->search(\%tuple1)->count == 1, "MAT tuple added");

}

done_testing();
