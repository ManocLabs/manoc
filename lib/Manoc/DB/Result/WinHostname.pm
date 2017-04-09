# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::WinHostname;


use parent 'Manoc::DB::Result';
use strict;
use warnings;

__PACKAGE__->load_components(
    qw/
        +Manoc::DB::Helper::Row::TupleArchive
        +Manoc::DB::InflateColumn::IPv4
        /
);

__PACKAGE__->table('win_hostname');

__PACKAGE__->add_columns(
    'name' => {
        data_type   => 'char',
        size        => 255,
        is_nullable => 0,
    },
    'ipaddr' => {
        data_type    => 'char',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1
    },
);

__PACKAGE__->set_tuple_archive_columns(qw(name ipaddr));

__PACKAGE__->set_primary_key(qw(name ipaddr firstseen));

__PACKAGE__->resultset_class('Manoc::DB::ResultSet::WinHostname');

sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index(
        name   => 'idx_winhostname_ipaddr',
        fields => ['ipaddr']
    );
}
1;
