package App::Manoc::DB::Result::IPBlock;
#ABSTRACT: A model object for IP address blocks

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('ip_block');
__PACKAGE__->resultset_class('App::Manoc::DB::ResultSet::IPBlock');

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
    dhcp_range => 'App::Manoc::DB::Result::DHCPSubnet',
    { 'foreign.range_id' => 'self.id' },
);

=method arp_entries

Return a resultset for all entries in Arp with IP addresses in this block

=cut

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

=method ip_entries

Return a resultset for all entries IP contained in this block

=cut

sub ip_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('IPAddressInfo');
    $rs = $rs->search(
        {
            'ipaddr' => {
                -between => [ $self->from_addr->padded, $self->to_addr->padded ]
            }
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method contained_networks

Return all network contained in this block

=cut

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

=method container_network

Return the smallest network containing this block

=cut

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

=for Pod::Coverage sqlt_deploy_hook

=cut

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
