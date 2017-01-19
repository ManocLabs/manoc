use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Manoc::Controller::Arp';
    use_ok 'Manoc::Controller::Auth';
    use_ok "Manoc::Controller::Building";
    use_ok 'Manoc::Controller::DHCPServer';
    use_ok 'Manoc::Controller::DHCPSubnet';
    use_ok 'Manoc::Controller::Device';
    use_ok 'Manoc::Controller::Error';
    use_ok 'Manoc::Controller::Group';
    use_ok 'Manoc::Controller::HWAsset';
    use_ok 'Manoc::Controller::IPBlock';
    use_ok 'Manoc::Controller::IPNetwork';
    use_ok 'Manoc::Controller::Interface';
    use_ok 'Manoc::Controller::Ip';
    use_ok 'Manoc::Controller::Mac';
    use_ok 'Manoc::Controller::Rack';
    use_ok 'Manoc::Controller::Search';
    use_ok 'Manoc::Controller::Server';;
    use_ok 'Manoc::Controller::ServerHW';
    use_ok 'Manoc::Controller::User';
    use_ok 'Manoc::Controller::VirtualInfr';
    use_ok 'Manoc::Controller::VirtualMachine';
    use_ok 'Manoc::Controller::Vlan';
    use_ok 'Manoc::Controller::VlanRange'
};

done_testing();
