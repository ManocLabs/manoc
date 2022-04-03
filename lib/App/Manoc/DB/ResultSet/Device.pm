package App::Manoc::DB::ResultSet::Device;
#ABSTRACT: ResultSet class for Device

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

    my $type    = $query->query_type;
    my $pattern = $query->sql_pattern;

    my $filter;
    my $match;

    if ( $type eq 'inventory' || $type eq 'device' ) {
        $filter = { name => { -like => $pattern } };
        $match  = sub { shift->name };
    }
    elsif ( $type eq 'address' ) {
        $filter = { 'mng_address' => { -like => $pattern } };
        $match  = sub { shift->mng_address->address };
    }
    elsif ( $type eq 'note' ) {
        $filter = { notes => { -like => $pattern } };
        $match  = sub { shift->name };
    }
    else {
        return;
    }

    my $rs = $self->search( $filter, { order_by => ['name'] } );
    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Row->new(
            {
                row   => $e,
                match => $match->($e)
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
