# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::DHCPNetwork;

use Moose;

#  'extends' since we are using Moose
extends 'DBIx::Class::Core';

use Manoc::IPAddress::IPv4Network;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dhcp_network');

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
    'range_from' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 0,
        ipv4_address => 1,
    },
    'range_to' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 0,
        ipv4_address => 1,
    },
    'dhcp_server' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->belongs_to( dhcp_server => 'Manoc::DB::Result::DHCPServer' );

__PACKAGE__->has_one(
    network =>
    'Manoc::DB::Result::IPNetwork',
    { 'foreign.dhcpnet_id' => 'self.id' },
  );

__PACKAGE__->has_many(
    leases =>
    'Manoc::DB::Result::DHCPLease',
    { 'foreign.dhcpnet_id' => 'self.id' },
  );

__PACKAGE__->has_many(
    reservations =>
    'Manoc::DB::Result::DHCPReservation',
    { 'foreign.dhcpnet_id' => 'self.id' },
  );

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
