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
__PACKAGE__->resultset_class('Manoc::DB::ResultSet::DHCPNetwork');

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
);


__PACKAGE__->belongs_to( network => 'Manoc::DB::Result::IPNetwork' );

__PACKAGE__->might_have(
    IPBlock => 'Manoc::DB::Result::IPBlock', 
    { 'foreign.dhcp_range' => 'self.id' },
  );


