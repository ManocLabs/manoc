package App::Manoc::DB::ResultSet::DeviceIfStatus;
#ABSTRACT: ResultSet class for IfStatus
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

    my $type    = $query->query_type;
    my $pattern = $query->sql_pattern;

    return unless $type eq 'inventory';

    my $rs = $self->search(
        {
            description => { '-like' => $pattern }
        },
        {
            order_by => 'description',
            prefetch =>  { 'interface' => 'device' },
        },
    );
    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Iface->new(
            {
                interface => $e->interface,
                text      => $e->description,
            }
        );
        $result->add_item($item);
    }
}

1;
