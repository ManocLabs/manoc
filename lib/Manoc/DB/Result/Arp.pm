# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Arp;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(qw/
				   +Manoc::DB::InflateColumn::IPv4
				   +Manoc::DB::Helper::Row::TupleArchive
			       /);

__PACKAGE__->table('arp');

__PACKAGE__->add_columns(
    'ipaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15,
	ipv4_address => 1,
    },
    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17,
    },
    'vlan' => {
        data_type     => 'int',
        default_value => 1,
        is_nullable   => 0,
        size          => 11
    },
);

__PACKAGE__->set_tuple_archive_columns(qw(macaddr ipaddr vlan));

__PACKAGE__->set_primary_key( 'ipaddr', 'macaddr', 'firstseen', 'vlan' );
__PACKAGE__->resultset_class('Manoc::DB::ResultSet::Arp');



sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index( name => 'idx_arp_mac', fields => ['macaddr'] );
    $sqlt_schema->add_index( name => 'idx_arp_ip',  fields => ['ipaddr'] );
    $sqlt_schema->add_index( name => 'idx_arp_ipmac',  fields => ['ipaddr', 'macaddr'] );
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
