package App::Manoc::DB::ResultSet::Ip;
#ABSTRACT: ResultSet class for Ip

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::IPAddr;

=method manoc_search( $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $query_type = $query->query_type;
    my $pattern    = $query->sql_pattern;

    my $filter;

    if ( $query_type eq 'ipaddr' ) {
        $filter = { ipaddr => { '-like' => $pattern } };
    }
    elsif ( $query_type eq 'notes' ) {
        $filter = { notes => { '-like' => $pattern } };
    }
    elsif ( $query_type eq 'inventory' ) {
        $filter = { description => { '-like' => $pattern } };
    }
    else {
        return;
    }

    my $rs = $self->search( $filter, { order_by => 'ipaddr' } );

    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::IPAddr->new(
            {
                match   => $e->ipaddr->address,
                address => $e->ipaddr,
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
