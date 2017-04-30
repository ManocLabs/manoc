package App::Manoc::Search::Item::VirtualMachine;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'virtualmachine' );

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

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args = $_[0];
        my $v    = $args->{vm};
        if ($v) {
            $args->{id}   = $v->id;
            $args->{name} = $v->name;
            $args->{match} ||= $v->name;
        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
