package App::Manoc::Model::ManocDB;

use Moose;
extends 'Catalyst::Model::DBIC::Schema';

##VERSION

use namespace::autoclean;

__PACKAGE__->config( schema_class => 'App::Manoc::DB', );

has 'search_engine' => (
    is      => 'ro',
    isa     => 'App::Manoc::Search::Engine',
    lazy    => 1,
    builder => '_build_search_engine',
);

sub _build_search_engine {
    my $self = shift;
    return App::Manoc::Search::Engine->new( { schema => $self->schema } );
}

sub search {
    my ( $self, $query_string, $params ) = @_;

    my $engine = $self->search_engine;

    my $q = App::Manoc::Search::Query->new( { search_string => $query_string } );

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

App::Manoc::Model::ManocDB - Catalyst DBIC Schema Model

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<App::Manoc::DB>

=cut

__PACKAGE__->meta->make_immutable;
1;
