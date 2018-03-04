package App::Manoc::DB::ResultSet::IPNetwork;
#ABSTRACT: ResultSet class for IPNetwork

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);
use App::Manoc::DB::Search::Result::Row;
use App::Manoc::Utils::IPAddress qw(check_addr);

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

=method included_by_subnet( $network, [$prefix] )

Return a resultset for all IPNetwork contained in  C<$network>.

=cut

sub included_by_subnet {
    my ( $self, $network, $prefix ) = @_;

    if ( !blessed($network) || !$network->isa('App::Manoc::IPAddress::IPv4Network') ) {
        $prefix //= 24;
        $network = App::Manoc::IPAddress::IPv4Network->new( $network, $prefix );
    }

    my $start_addr = $network->address->padded;
    my $end_addr   = $network->broadcast->padded;

    my $rs = $self->search(
        {
            'address'   => { '>=' => $start_addr },
            'broadcast' => { '<=' => $end_addr },
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $query_type = $query->query_type;
    my $pattern    = $query->sql_pattern;
    my $subnet     = $query->subnet;

    my $rs;

    if ( $query_type eq 'subnet' ) {

        if ( defined($subnet) ) {
            return unless ( check_addr($subnet) );
            my $prefix = $query->prefix // '24';
            $rs = $self->included_by_subnet( $subnet, $prefix );
        }
        else {
            # if subnet isn't defined, the scope was specified
            # by the user and we have a pattern
            $rs = $self->search( address => { -like => $pattern } );
        }
    }
    elsif ( $query_type eq 'inventory' ) {
        $rs = $self->search( { name => { '-like' => $pattern } } );
    }
    else {
        return;
    }

    $rs = $rs->search( {}, { order_by => 'name' } );
    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Row->new(
            {
                row   => $e,
                match => $e->name,
            }
        );
        $result->add_item($item);
    }

}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
