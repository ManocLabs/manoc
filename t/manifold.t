use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Manoc::Manifold', 'load manifold registry');
};

ok(Manoc::Manifold->load_namespace, 'load manifold names');

{
    my %manifolds = map { $_ => 1 } Manoc::Manifold->manifolds;

    ok($manifolds{SNMP}, 'SNMP manifold found');
    ok($manifolds{'Telnet::IOS'}, 'Telnet::IOS manifold found');
    ok($manifolds{'SSH::Linux'},  'Linux::SSH manifold found');
}

cmp_ok( Manoc::Manifold->name_mappings->{SNMP}, 'eq',
	    'Manoc::Manifold::SNMP',
	    'Mapping name for SNMP manifold');


SKIP: {
    eval { require 'Net::Telnet::Cisco' };
    skip 'Net::Telnet::Cisco based tests', 1 unless $@;

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
        eval { require 'SNMP::Info' };
    
    my $m = Manoc::Manifold->new_manifold('SNMP',
                                          credentials => { snmp_community => 'public' },
                                          host => '127.0.0.1');
    ok($m, 'Create SNMP manifold');
}

done_testing();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
