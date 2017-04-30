use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'App::Manoc::Utils::IPAddress' };

BEGIN { use_ok 'App::Manoc::IPAddress::IPv4' };
{
    my $addr = App::Manoc::IPAddress::IPv4->new('10.1.100.1');
    ok( $addr, 'create IPv4 Object from unpadded address');

    # stringify
    cmp_ok( $addr->padded, 'eq', '010.001.100.001', 'padded');
    cmp_ok( $addr->unpadded, 'eq', '10.1.100.1', 'unpadded');
    cmp_ok( "$addr", 'eq', '10.1.100.1', 'stringify');
    cmp_ok( $addr->address, 'eq', $addr->unpadded, "legacy address method");

    # cmp overload
    cmp_ok( $addr eq '10.1.100.1', '==', 1, "operator eq string");
    cmp_ok( $addr eq  App::Manoc::IPAddress::IPv4->new('10.1.100.1'),  '==', 1, "operator eq object");
    cmp_ok( $addr gt '2.1.1.1', '==', 1, "operator lt string");
    cmp_ok( $addr gt App::Manoc::IPAddress::IPv4->new('2.1.1.1'), '==', 1, "operator lt object");
    cmp_ok( $addr lt '192.10.0.0', '==', 1, "operator lt string");
    cmp_ok( $addr lt App::Manoc::IPAddress::IPv4->new('192.10.0.0'), '==', 1, "operator lt object");

    # <=> overload
    ok( $addr < App::Manoc::IPAddress::IPv4->new('192.10.0.0'), "operator < object");
    ok( $addr > App::Manoc::IPAddress::IPv4->new('10.0.0.0'),  "operator > object");

}

BEGIN { use_ok 'App::Manoc::IPAddress::IPv4Network' };
{
    my $net = App::Manoc::IPAddress::IPv4Network->new('192.168.1.0', '24');
    ok( $net, 'create IPv4 Network from address/prefix');

    cmp_ok( "$net", 'eq', '192.168.1.0/24', 'stringify');
    cmp_ok( $net->_stringify, 'eq', '192.168.1.0/24', 'stringify');

    cmp_ok( $net->address,    'eq', '192.168.1.0',   'address');
    cmp_ok( $net->prefix,     '==', '24',            'prefix');
    cmp_ok( $net->netmask,    'eq', '255.255.255.0', 'netmask');
    cmp_ok( $net->broadcast,  'eq', '192.168.1.255', 'broadcast');
    cmp_ok( $net->first_host, 'eq', '192.168.1.1',   'first host');
    cmp_ok( $net->last_host,  'eq', '192.168.1.254', 'last host');
    cmp_ok( $net->wildcard,   'eq', '0.0.0.255',     'wildcard');

    ok( $net->contains_address( App::Manoc::IPAddress::IPv4->new('192.168.1.5'),
                                '192.168.1.0/24 contains 192.168.1.5') );
    ok( ! $net->contains_address( App::Manoc::IPAddress::IPv4->new('192.168.0.5'),
                                '192.168.1.0/24 does not contain 192.168.0.5') );
}

{
    my $net = App::Manoc::IPAddress::IPv4Network->new('10.10.0.0', '255.255.0.0');
    ok( $net, 'Create IPv4 Network from address/netmask');

    cmp_ok( "$net", 'eq', '10.10.0.0/16', 'stringify');

}


{
    my $net = App::Manoc::IPAddress::IPv4Network->new('10.10.0.0', '0');
    ok( $net, 'Create IPv4 Network with /0 prefix');

    cmp_ok( "$net", 'eq', '0.0.0.0/0', 'stringify');
}

{
    my $net = App::Manoc::IPAddress::IPv4Network->new('1.2.3.4', '32');
    ok( $net, 'Create IPv4 Network with /32 prefix');

    cmp_ok( "$net", 'eq', '1.2.3.4/32', 'stringify');
}

done_testing();

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
