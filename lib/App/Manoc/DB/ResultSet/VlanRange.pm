package App::Manoc::DB::ResultSet::VlanRange;
#ABSTRACT: ResultSet class for VlanRange

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

=method get_overlap_ranges( $start, $end )

Return all the VlanRange which are overlap the given internal.

=cut

sub get_overlap_ranges {
    my ( $self, $start, $end ) = @_;

    my $conditions = [
        {
            start => { '<=' => $start },
            end   => { '>=' => $start },
        },
        {
            start => { '<=' => $end },
            end   => { '>=' => $end },
        },
    ];

    return
        wantarray ? $self->search($conditions)->all :
        $self->search_rs($conditions);
}

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $query_type = $query->query_type;

    return unless $query_type eq 'inventory';

    my $pattern = $query->sql_pattern;

    my $rs = $self->search( { name => { '-like' => $pattern } }, { order_by => 'id' } );

    while ( my $e = $rs->next ) {

        my $item = App::Manoc::DB::Search::Result::VlanRange->new(
            {
                name  => $e->name,
                match => $e->name,
            }
        );
        $result->add_item($item);
    }
}

=head1 SEE ALSO

L<DBIx::Class::ResultSet>

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
