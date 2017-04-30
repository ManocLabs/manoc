package App::Manoc::DB::Result::DHCPServer;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use App::Manoc::IPAddress::IPv4Network;

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dhcp_server');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64,
    },
    'domain_name' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64,
    },
    'domain_nameserver' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64,
    },
    'ntp_server' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64,
    },
    'default_lease_time' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'max_lease_time' => {
        data_type   => 'int',
        is_nullable => 1,
    },

);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->has_many(
    'dhcp_subnets' => 'App::Manoc::DB::Result::DHCPSubnet',
    { 'foreign.dhcp_server_id' => 'self.id' },
);

__PACKAGE__->has_many(
    'dhcp_shared_networks' => 'App::Manoc::DB::Result::DHCPSharedNetwork',
    { 'foreign.dhcp_server_id' => 'self.id' },
);

__PACKAGE__->has_many(
    'dhcp_leases' => 'App::Manoc::DB::Result::DHCPLease',
    { 'foreign.dhcp_server_id' => 'self.id' },
);

__PACKAGE__->has_many(
    'dhcp_reservations' => 'App::Manoc::DB::Result::DHCPReservation',
    { 'foreign.dhcp_server_id' => 'self.id' },
);

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
