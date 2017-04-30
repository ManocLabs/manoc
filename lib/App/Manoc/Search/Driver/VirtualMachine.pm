package App::Manoc::Search::Driver::VirtualMachine;

use Moose;

##VERSION

use App::Manoc::Search::Item::VirtualMachine;

extends 'App::Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    my $it =
        $schema->resultset('VirtualMachine')
        ->search( [ { uuid => { -like => $pattern } }, { name => { -like => $pattern } } ],
        { order_by => 'name' } );

    while ( my $v = $it->next ) {
        my $item = App::Manoc::Search::Item::VirtualMachine->new( { vm => $v } );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
