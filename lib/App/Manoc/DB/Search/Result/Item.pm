package App::Manoc::DB::Search::Result::Item;
#ABSTRACT: A generic search result item

use Moose;

##VERSION

=attr timestamp

unixtime

=cut

has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

=attr match

=cut

has 'match' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=attr key

used for sorting, defaults to match

=cut

has 'key' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_key',
);

=attr text

=cut

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

sub _build_key { $_[0]->match }

no Moose;
__PACKAGE__->meta->make_immutable;
