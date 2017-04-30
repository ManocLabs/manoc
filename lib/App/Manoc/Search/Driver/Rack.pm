package App::Manoc::Search::Driver::Rack;

use Moose;

##VERSION

use App::Manoc::Search::Item::Rack;

extends 'App::Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    return $self->_search( $query, $result );
}

sub search_rack {
    my ( $self, $query, $result ) = @_;
    return $self->_search( $query, $result );
}

sub _search {
    my ( $self, $query, $result ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    my $it =
        $schema->resultset('Rack')
        ->search( [ { name => { -like => $pattern } } ], { order_by => 'name' } );

    while ( my $e = $it->next ) {
        my $item = App::Manoc::Search::Item::Rack->new( { rack => $e } );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
