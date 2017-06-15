package App::Manoc::DB::Search;
#ABSTRACT: Manoc internal search engine

use Moose;

##VERSION

use App::Manoc::DB::Search::Result;

has schema => (
    is       => 'ro',
    required => 1,
);

has _sources => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_sources',
);

sub _build_sources {
    my ($self) = @_;

    my @sources;

    foreach my $name ( $self->schema->sources ) {
        $self->schema->source($name)->resultset->can('manoc_search') and
            push @sources, $name;
    }

    return \@sources;
}

=method search($query)

Run a search using the query object C<$query>.

=cut

sub search {
    my ( $self, $query ) = @_;

    my $result = App::Manoc::DB::Search::Result->new( { query => $query } );

    foreach my $source ( @{ $self->_sources } ) {
        $self->schema->source($source)->resultset->manoc_search( $query, $result );
    }

    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;
