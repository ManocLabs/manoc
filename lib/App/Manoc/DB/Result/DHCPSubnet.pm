package App::Manoc::DB::Result::DHCPSubnet;
#ABSTRACT: A model object for DHCP subnets

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use App::Manoc::IPAddress::IPv4Network;

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dhcp_subnet');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    'name' => {
        data_type => 'varchar',
        size      => 64,
    },
    'domain_name' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64,
    },
    'domain_nameserver' => {
        data_type    => 'varchar',
        is_nullable  => 1,
        size         => 15,
        ipv4_address => 1,
    },
    'ntp_server' => {
        data_type    => 'varchar',
        is_nullable  => 1,
        size         => 15,
        ipv4_address => 1,
    },
    'default_lease_time' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'max_lease_time' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'dhcp_server_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    network_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    range_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    'dhcp_shared_network_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->belongs_to(
    dhcp_server => 'App::Manoc::DB::Result::DHCPServer',
    { 'foreign.id' => 'self.dhcp_server_id' },
);

__PACKAGE__->belongs_to(
    network => 'App::Manoc::DB::Result::IPNetwork',
    'network_id',
);

__PACKAGE__->belongs_to(
    range => 'App::Manoc::DB::Result::IPBlock',
    'range_id',
);

__PACKAGE__->belongs_to(
    dhcp_shared_network => 'App::Manoc::DB::Result::DHCPSharedNetwork',
    { 'foreign.id' => 'self.dhcp_shared_network_id' },
);

__PACKAGE__->has_many(
    reservations => 'App::Manoc::DB::Result::DHCPReservation',
    { 'foreign.dhcp_subnet_id' => 'self.id' },
);

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
