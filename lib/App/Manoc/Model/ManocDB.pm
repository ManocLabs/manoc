package App::Manoc::Model::ManocDB;
#ABSTRACT:  Catalyst DBIC Schema Model for Manoc

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<App::Manoc::DB>

=cut

use Moose;
extends 'Catalyst::Model::DBIC::Schema';

##VERSION

use namespace::autoclean;

__PACKAGE__->config( schema_class => 'App::Manoc::DB', );

has 'search_engine' => (
    is      => 'ro',
    isa     => 'App::Manoc::DB::Search',
    lazy    => 1,
    builder => '_build_search_engine',
);

=method search( $query_string, $params )

Run query using L<App::Manoc::DB> C<manoc_search> method.

=cut

sub search {
    my $self = shift;
    return $self->schema->manoc_search(@_);
}

__PACKAGE__->meta->make_immutable;
1;
