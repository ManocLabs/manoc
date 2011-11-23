# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Arp;

use base 'DBIx::Class';
use strict;
use warnings;

use Manoc::Utils;

__PACKAGE__->load_components(qw/FilterColumn Core/);
__PACKAGE__->table('arp');

__PACKAGE__->add_columns(
    'ipaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15
    },
    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17,

    },
    'firstseen' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11
    },
    'lastseen' => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },
    'vlan' => {
        data_type     => 'int',
        default_value => 1,
        is_nullable   => 0,
        size          => 11
    },
    'archived' => {
        data_type     => 'int',
        default_value => 0,
        is_nullable   => 0,
        size          => 1
    },
);

__PACKAGE__->set_primary_key( 'ipaddr', 'macaddr', 'firstseen', 'vlan' );
__PACKAGE__->resultset_class('Manoc::DB::ResultSet::Arp');

__PACKAGE__->filter_column(
			   ipaddr => {
				    filter_to_storage   => sub { Manoc::Utils::padded_ipaddr($_[1]) },
				   }
			  );

sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index( name => 'idx_mac', fields => ['macaddr'] );
}

1;

