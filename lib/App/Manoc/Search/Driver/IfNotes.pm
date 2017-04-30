# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Driver::IfNotes;
use Moose;
use App::Manoc::Search::Item::Iface;

extends 'App::Manoc::Search::Driver';

sub search_note {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    $it = $schema->resultset('IfNotes')
        ->search( { notes => { '-like' => $pattern } }, { order_by => 'notes' } );
    while ( $e = $it->next ) {
        my $item = App::Manoc::Search::Item::Iface->new(
            {
                device    => $e->device,
                interface => $e->interface,
                text      => $e->notes,
                match     => $e->device->address,
            }
        );
        $result->add_item($item);
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;
