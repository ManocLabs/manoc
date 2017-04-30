package App::Manoc::Search::Item::Rack;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item';

has 'id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '+item_type' => ( default => 'rack' );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args = $_[0];
        my $b    = $args->{rack};
        if ($b) {
            $args->{id}   = $b->id;
            $args->{name} = $b->name;
            $args->{match} ||= $b->name;
        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
