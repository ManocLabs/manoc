package App::Manoc::DB::Search::Result::Group;
#ABSTRACT: A role for group of result items

use Moose::Role;

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

no Moose::Role;
1;
