# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::Building;
use Moose;
use Manoc::Search::Item::Building;

extends 'Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    return $self->_search( $query, $result );
}

sub search_building {
    my ( $self, $query, $result ) = @_;
    return $self->_search( $query, $result );
}

sub _search {
    my ( $self, $query, $result ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    my $it =
        $schema->resultset('Building')
        ->search(
        [ { description => { -like => $pattern } }, { name => { -like => $pattern } } ],
        { order_by => 'description' } );

    while ( my $b = $it->next ) {
        my $item = Manoc::Search::Item::Building->new( { building => $b } );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
