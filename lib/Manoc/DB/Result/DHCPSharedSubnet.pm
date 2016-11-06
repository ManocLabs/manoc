# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::DHCPSharedSubnet;

use Moose;

#  'extends' since we are using Moose
extends 'DBIx::Class::Core';

use Manoc::IPAddress::IPv4Network;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('dhcp_shared_subnet');

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
    'dhcp_server_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->belongs_to( 
    'dhcp_server' => 'Manoc::DB::Result::DHCPServer',
    { 'foreign.id' => 'self.dhcp_server_id' },
);

 __PACKAGE__->has_many( 
     'dhcp_subnet' => 'Manoc::DB::Result::DHCPSubnet',
      { 'foreign.dhcp_shared_id' => 'self.id' },
      { cascade_delete => 0}
 );


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
