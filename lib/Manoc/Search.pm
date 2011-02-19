# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Search;
use Moose::Role;
use Manoc::Search::Engine;
use Manoc::Search::Query;
use Manoc::Utils qw(str2seconds);

has 'manoc_search_engine' => ( is => 'rw' );

sub search {
    my ( $self, $schema, $query_string, $params ) = @_;

    my $engine = $self->manoc_search_engine;
    if ( !defined($engine) ) {
        $engine = Manoc::Search::Engine->new( { schema => $schema } );
        $self->manoc_search_engine($engine);
    }

    my $q = Manoc::Search::Query->new( { search_string => $query_string } );

    # use params to refine query
    if ( $params->{limit} && !defined( $q->limit ) ) {
        $q->limit( str2seconds( $params->{limit} ) );
    }
    if ( $params->{type} && !defined( $q->query_type ) ) {
        $q->query_type( $params->{type} );
    }

    $q->parse;

    return $engine->search($q);
}

1;
