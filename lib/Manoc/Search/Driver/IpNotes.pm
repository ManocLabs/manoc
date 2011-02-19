# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::IpNotes;
use Moose;
use Manoc::Search::Item::IpAddr;

extends 'Manoc::Search::Driver';

sub search_note {
    my ( $self, $query, $result ) = @_;

    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    my $it = $schema->resultset('IpNotes')->search(
        notes => { '-like' => $pattern },
        { order_by => 'notes' }
    );
    while ( my $e = $it->next ) {
        my $item = Manoc::Search::Item::IpAddr->new(
            {
                match => $e->ipaddr,
                addr  => $e->ipaddr,
                text  => $e->notes,
            }
        );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
