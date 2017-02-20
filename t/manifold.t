use strict;
use warnings;
use Test::More;

BEGIN {
    use Manoc::Logger;
    Manoc::Logger->init();

    use_ok('Manoc::Manifold', 'load manifold registry');
};

ok(Manoc::Manifold->load_namespace, 'load manifold names');

{
    my %manifolds = map { $_ => 1 } Manoc::Manifold->manifolds;

    ok($manifolds{'SNMP::Simple'}, 'SNMP Simple manifold found');
    ok($manifolds{'SNMP::Info'},   'SNMP Info manifold found');
    ok($manifolds{'Telnet::IOS'},  'Telnet::IOS manifold found');
    ok($manifolds{'SSH::Linux'},   'Linux SSH manifold found');
    ok($manifolds{'SSH::Linux'},   'Fortinet SSH manifold found');
}

cmp_ok( Manoc::Manifold->name_mappings->{'SNMP::Info'}, 'eq',
	    'Manoc::Manifold::SNMP::Info',
	    'Mapping name for SNMP manifold');


SKIP: {
    skip 'Net::Telnet::Cisco based tests', 1 unless
        eval { require 'Net::Telnet::Cisco' };

    my $m = Manoc::Manifold->new_manifold('Telnet::IOS',
                                          credentials => {
                                              username => 'admin',
                                              password => 'test',
                                          },
					  host => '127.0.0.1');
    ok($m, 'Create Telnet::IOS manifold');
}

SKIP: {
    skip 'SNMP::Info based tests', 1 unless
        eval { require SNMP::Info };

    my $m = Manoc::Manifold->new_manifold('SNMP::Info',
                                          credentials => { snmp_community => 'public' },
                                          host => '127.0.0.1');
    ok($m, 'Create SNMP manifold');
}


SKIP: {
    skip 'Net::SNMP based tests', 7 unless
        eval {  require Net::SNMP } && $ENV{MANOC_TEST_SNMP_HOST};

    # Please use a Linux host w/ NetSNMP

    my $host      = $ENV{MANOC_TEST_SNMP_HOST};
    my $community = $ENV{MANOC_TEST_SNMP_COMMUNITY} || 'public';

    my $m = Manoc::Manifold->new_manifold('SNMP::Simple',
                                          credentials => { snmp_community => $community },
                                          host => $host );
    ok($m, 'Create SNMP manifold');
    ok($m->connect, 'SNMP::Simple connect successful');

    my $vendor = $m->vendor;
    ok($vendor, "SNMP::Simple returned vendor '$vendor'");

    my $os = $m->os;
    ok($os, "SNMP::Simple returned os '$os'");

    my $os_ver = $m->os_ver;
    ok($os_ver, "SNMP::Simple returned os '$os_ver'");

    my $boottime = $m->boottime;
    ok($boottime, "SNMP::Simple returned bootime ".localtime($boottime));

    my $dev_descr = $m->snmp_hrDeviceDescr;
    cmp_ok(ref($dev_descr), 'eq', 'HASH', "SNMP::Simple fetched hrDeviceDesc column");
}



done_testing();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
