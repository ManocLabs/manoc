package App::Manoc::Search::Driver::Vlan;

use Moose;

##VERSION

use App::Manoc::Search::Item::Vlan;

extends 'App::Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    $it = $schema->resultset('Vlan')
        ->search( { name => { '-like' => $pattern } }, { order_by => 'id' } );
    while ( $e = $it->next ) {
        my $item = App::Manoc::Search::Item::Vlan->new( { vlan => $e } );
        $result->add_item($item);
    }

    $it = $schema->resultset('Vlan')
        ->search( { id => { '-like' => $pattern } }, { order_by => 'id' } );
    while ( $e = $it->next ) {
        my $item = App::Manoc::Search::Item::Vlan->new( { vlan => $e } );
        $result->add_item($item);
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;
