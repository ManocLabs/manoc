# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::IPBlock;

use parent 'Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('ip_block');
__PACKAGE__->resultset_class('Manoc::DB::ResultSet::IPBlock');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
    },
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'from_addr' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 0,
        ipv4_address => 1,
    },
    'to_addr' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 0,
        ipv4_address => 1,
    },
    'description' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 255
    },
);

__PACKAGE__->set_primary_key(qw(id));

__PACKAGE__->might_have(
    dhcp_range => 'Manoc::DB::Result::DHCPSubnet',
    { 'foreign.range_id' => 'self.id' },
);

sub arp_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Arp');
    $rs = $rs->search(
        {
            'ipaddr' => {
                -between => [ $self->from_addr->padded, $self->to_addr->padded ]
            }
        }
    );
    return wantarray ? $rs->all : $rs;
}

sub ip_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Ip');
    $rs = $rs->search(
        {
            'ipaddr' => {
                -between => [ $self->from_addr->padded, $self->to_addr->padded ]
            }
        }
    );
    return wantarray ? $rs->all : $rs;
}

sub contained_networks {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('IPNetwork');
    $rs = $rs->search(
        {
            'address'   => { '>=' => $self->from_addr->padded },
            'broadcast' => { '<=' => $self->to_addr->padded }
        }
    );

    return wantarray ? $rs->all : $rs;
}

sub container_network {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('IPNetwork');
    $rs = $rs->search(
        {
            'address'   => { '<=' => $self->from_addr->padded },
            'broadcast' => { '>=' => $self->to_addr->padded }
        },
        {
            order_by => [ { -asc => 'address' }, { -desc => 'broadcast' } ],
        }
    );
    return $rs->first;
}

sub sqlt_deploy_hook {
    my ( $self, $sqlt_table ) = @_;

    $sqlt_table->add_index(
        name   => 'idx_ipblock_from_to',
        fields => [ 'from_addr', 'to_addr' ]
    );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
