package App::Manoc::Search::Result;

use Moose;

##VERSION

use App::Manoc::Search::Item::IpAddr;
use App::Manoc::Search::Item::MacAddr;
use App::Manoc::Search::Item::WinLogon;
use App::Manoc::Search::Widget::ApplyRole;

=attr query

=cut

has query => ( is => 'ro' );

=attr item_by_match

=cut

has item_by_match => (
    is      => 'ro',
    isa     => 'HashRef[String]',
    default => sub { {} },
);

=attr message

=cut

has message => (
    is  => 'rw',
    isa => 'Str',
);

=attr groups

The list of L<App::Manoc::Search::Item::Group> objects which will
contain the result items.

=cut

has groups => (
    is      => 'ro',
    isa     => 'ArrayRef',
    writer  => '_groups',
    default => sub { [] },
);

my %GROUP_ITEM = (
    'logon'   => 'App::Manoc::Search::Item::WinLogon',
    'ipaddr'  => 'App::Manoc::Search::Item::IpAddr',
    'macaddr' => 'App::Manoc::Search::Item::MacAddr',
);

=method add_item

Add a new L<App::Manoc::Search::Item> to the result. Creates a new
group if the item has a new match.

=cut

sub add_item {
    my ( $self, $item ) = @_;

    my $match = $item->match;

    my $query_type = $self->query->query_type;

    my $group = $self->item_by_match->{$match};
    if ( !defined($group) ) {
        my $class = $GROUP_ITEM{$query_type};
        $class ||= 'App::Manoc::Search::Item::Group';

        $group = $class->new( { match => $match } );
        $self->item_by_match->{$match} = $group;

        push @{ $self->{groups} }, $group;
    }

    $group->add_item($item);
}

=method items

Return all the result items, sorted by groups.

=cut

sub items {
    my $self = shift;
    $self->sort_items;

    return $self->groups;
}

=method sort_items

Sort the result group by key.

=cut

sub sort_items {
    my $self = shift;

    foreach my $group ( values %{ $self->item_by_match } ) {
        $group->sort_items;
    }

    my $groups = $self->groups;
    my @g = sort { $a->key cmp $b->key } @$groups;
    $self->_groups( \@g );
}

=method load_widgets

Load widget for all result items.

=cut

sub load_widgets {
    my $self = shift;

    foreach my $group ( values %{ $self->item_by_match } ) {
        $group->load_widgets(@_);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
