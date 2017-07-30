package App::Manoc::DB::ResultSet::Rack;
#ABSTRACT: ResultSet class for Rack

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
    return unless $type eq 'asset' or $type eq 'building';

    my $pattern = $query->sql_pattern;

    my $rs = $self->search(
        [ { description => { -like => $pattern } }, { name => { -like => $pattern } } ],
        { order_by => 'name' } );

    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Row->new(
            match => $e->name,
            row   => $e,
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
