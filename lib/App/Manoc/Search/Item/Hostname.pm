package App::Manoc::Search::Item::Hostname;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'hostname' );

has 'ipaddr' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args = $_[0];
        my $b    = $args->{hostname};
        if ($b) {
            $args->{ipaddr} = $b->ipaddr->unpadded;
            $args->{name}   = $b->name;
            $args->{match} ||= $b->name;
        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
