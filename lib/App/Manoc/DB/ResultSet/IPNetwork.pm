package App::Manoc::DB::ResultSet::IPNetwork;
#ABSTRACT: ResultSet class for IPNetwork

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

=method get_root_networks

Return a resultset containing all networks which are not contained by another
one.

=cut

sub get_root_networks {
    my ($self) = @_;

    my $me = $self->current_source_alias;
    my $rs = $self->search( { "$me.parent_id" => undef } );
    return wantarray ? $rs->all : $rs;
}

=method rebuild_tree

Recalculate parent relationship for all rows.

=cut

sub rebuild_tree {
    my $self = shift;

    my @nodes = $self->all();

    foreach my $node (@nodes) {
        my $supernet = $node->first_supernet();
        $supernet //= 0;
        $node->parent($supernet);
    }

}

=method including_address( $ipaddress )

Return a resultset for all IPNetwork containing C<$ipaddress>.

=cut

sub including_address {
    my ( $self, $ipaddress ) = @_;

    if ( blessed($ipaddress) &&
        $ipaddress->isa('App::Manoc::IPAddress::IPv4') )
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

=method including_address_ordered

Same as C<including_address> ordered by ordered by network address.

=cut

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
