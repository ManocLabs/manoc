package App::Manoc::Search::Driver::VlanRange;

use Moose;

##VERSION

use App::Manoc::Search::Item::VlanRange;

extends 'App::Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    $it = $schema->resultset('VlanRange')
        ->search( { name => { '-like' => $pattern } }, { order_by => 'id' } );

    while ( $e = $it->next ) {

        my $item = App::Manoc::Search::Item::VlanRange->new(
            {
                name  => $e->name,
                match => $e->name,
            }
        );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
