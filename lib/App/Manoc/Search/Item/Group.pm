package App::Manoc::Search::Item::Group;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'group' );

has 'items' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    writer  => '_items',
);

sub add_item {
    my ( $self, $item ) = @_;

    push @{ $self->items }, $item;
}

sub sort_items {
    my $self = shift;

    my @l = sort { $b->timestamp <=> $a->timestamp } @{ $self->items };
    $self->_items( \@l );
}

override load_widgets => sub {
    my $self = shift;

    foreach my $i ( @{ $self->items } ) {
        $i->load_widgets;
    }
    super();
};

no Moose;
__PACKAGE__->meta->make_immutable;
