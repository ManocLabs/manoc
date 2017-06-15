package App::Manoc::DB::ResultSet::IfNotes;
#ABSTRACT: ResultSet class for IfNotes
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::Iface;

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $type = $query->query_type;

    return unless $type eq 'notes';

    my $pattern = $query->sql_pattern;

    my $rs = $self->search( { notes => { '-like' => $pattern } }, { order_by => 'notes' } );
    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Iface->new(
            {
                device    => $e->device,
                interface => $e->interface,
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
