package App::Manoc::DB::ResultSet::Building;
#ABSTRACT: ResultSet class for Building

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::Row;

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $query_type = $query->query_type;
    return unless $query_type eq 'asset' or $query_type eq 'building';

    my $pattern = $query->sql_pattern;

    my $rs = $self->search(
        [ { description => { -like => $pattern } }, { name => { -like => $pattern } } ],
        { order_by => 'description' } );

    while ( my $b = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Row->new(
            match => $b->name,
            row   => $b,
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
