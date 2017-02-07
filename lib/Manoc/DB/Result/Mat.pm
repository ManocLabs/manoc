# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Mat;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(
    qw/
        +Manoc::DB::Helper::Row::TupleArchive
        /
);

__PACKAGE__->table('mat');

__PACKAGE__->add_columns(
    'macaddr' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },
    'device_id' => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    'interface' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64,
    },
    # firstseen, lastseen, archived added by TupleArchive

    'vlan' => {
        data_type     => 'int',
        default_value => 1,
        is_nullable   => 0,
        size          => 11
    },
);

__PACKAGE__->set_tuple_archive_columns( 'macaddr', 'device_id', 'interface', 'vlan' );

__PACKAGE__->set_primary_key( 'macaddr', 'device_id', 'firstseen', 'vlan' );

__PACKAGE__->belongs_to( 'device' => 'Manoc::DB::Result::Device', 'device_id' );

__PACKAGE__->resultset_class('Manoc::DB::ResultSet::Mat');

sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index( name => 'idx_mat_device',  fields => ['device_id'] );
    $sqlt_schema->add_index( name => 'idx_mat_macaddr', fields => ['macaddr'] );

    $sqlt_schema->add_index(
        name   => 'idx_mat_dev_iface',
        fields => [ 'device_id', 'interface' ]
    );

}

1;
