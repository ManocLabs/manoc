package App::Manoc::DB::ResultSet::Vlan;
#ABSTRACT: ResultSet class for Vlan

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $type = $query->query_type;

    return unless $type eq 'inventory';

    my $pattern = $query->sql_pattern;

    my $rs = $self->search( { id => { '-like' => $pattern } }, { order_by => 'id' } );
    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Row->new( { row => $e } );
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
