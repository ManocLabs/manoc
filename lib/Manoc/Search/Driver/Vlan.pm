# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::Vlan;
use Moose;
use Manoc::Search::Item::Vlan;

extends 'Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    $it = $schema->resultset('Vlan')->search(
        name => { '-like' => $pattern },
        { order_by => 'id' }
    );
    while ( $e = $it->next ) {
        my $item = Manoc::Search::Item::Vlan->new( { vlan => $e } );
        $result->add_item($item);
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;
