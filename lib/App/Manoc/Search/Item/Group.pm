package App::Manoc::Search::Item::Group;
#ABSTRACT: A group of result items

use Moose;

##VERSION

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'group' );

=attr items

The items in this group.

=cut

has 'items' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    writer  => '_items',
);

=method add_item

Add a result item to the group

=cut

sub add_item {
    my ( $self, $item ) = @_;

    push @{ $self->items }, $item;
}

=method sort_items

Sort items by timestamp

=cut

sub sort_items {
    my $self = shift;

    my @l = sort { $b->timestamp <=> $a->timestamp } @{ $self->items };
    $self->_items( \@l );
}

=method load_widgets

Load widget for all items in the group.

=cut

override load_widgets => sub {
    my $self = shift;

    foreach my $i ( @{ $self->items } ) {
        $i->load_widgets;
    }
    super();
};

no Moose;
__PACKAGE__->meta->make_immutable;
