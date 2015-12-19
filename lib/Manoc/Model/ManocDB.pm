# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Model::ManocDB;

use Moose;
extends 'Catalyst::Model::DBIC::Schema';
use namespace::autoclean;

__PACKAGE__->config( schema_class => 'Manoc::DB', );

has 'search_engine' => (
    is      => 'ro',
    isa     => 'Manoc::Search::Engine',
    lazy    => 1,
    builder => '_build_search_engine',
);

sub _build_search_engine {
    my $self = shift;
    return Manoc::Search::Engine->new( { schema => $self->schema } );
}

sub search {
    my ( $self, $query_string, $params ) = @_;

    my $engine = $self->search_engine;

    my $q = Manoc::Search::Query->new( { search_string => $query_string } );

    # use params to refine query
    if ( $params->{limit} && !defined( $q->limit ) ) {
        $q->limit( ( $params->{limit} ) );
    }
    if ( $params->{type} && !defined( $q->query_type ) ) {
        $q->query_type( $params->{type} );
    }
    $q->parse;

    return $engine->search($q);
}

=head1 NAME

Manoc::Model::ManocDB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<Manoc>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Manoc::DB>

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
