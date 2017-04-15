# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::IPNetwork;

use strict;
use warnings;

use parent 'Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

sub get_root_networks {
    my ($self) = @_;

    my $me = $self->current_source_alias;
    my $rs = $self->search( { "$me.parent_id" => undef } );
    return wantarray ? $rs->all : $rs;
}

sub rebuild_tree {
    my $self = shift;

    my @nodes = $self->all();

    foreach my $node (@nodes) {
        my $supernet = $node->first_supernet();
        $supernet //= 0;
        $node->parent($supernet);
    }

}

sub including_address {
    my ( $self, $ipaddress ) = @_;

    if ( blessed($ipaddress) &&
        $ipaddress->isa('Manoc::IPAddress::IPv4') )
    {
        $ipaddress = $ipaddress->padded;
    }

    my $rs = $self->search(
        {
            'address'   => { '<=' => $ipaddress },
            'broadcast' => { '>=' => $ipaddress },
        }
    );
    return wantarray ? $rs->all : $rs;
}

sub including_address_ordered {
    my $rs = shift->including_address(@_)->search( {}, { order_by => { -desc => 'address' } } );
    return wantarray ? $rs->all : $rs;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
