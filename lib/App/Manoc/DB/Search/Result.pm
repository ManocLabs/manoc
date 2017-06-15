package App::Manoc::DB::Search::Result;

use Moose;

##VERSION

use App::Manoc::DB::Search::Result::IPAddr;
use App::Manoc::DB::Search::Result::MacAddr;
use App::Manoc::DB::Search::Result::Name;

=attr query

=cut

has query => ( is => 'ro' );

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

=attr group_by_match

=cut

has group_by_match => (
    is      => 'ro',
    isa     => 'HashRef[String]',
    default => sub { {} },
);

=attr items

=cut

has items => (
    is      => 'ro',
    isa     => 'ArrayRef',
    writer  => '_items',
    default => sub { [] },
);

my %GROUP_ITEM = (
    'logon'   => 'App::Manoc::DB::Search::Result::Name',
    'ipaddr'  => 'App::Manoc::DB::Search::Result::IPAddr',
    'macaddr' => 'App::Manoc::DB::Search::Result::MacAddr',
);

=method add_item

Add a new L<App::Manoc::Search::Item> to the result. Creates a new
group if the item has a new match.

=cut

sub add_item {
    my ( $self, $item ) = @_;

    my $match = $item->match;

    my $query_type = $self->query->query_type;

    if ( my $group_class = $GROUP_ITEM{$query_type} ) {
        my $group = $self->group_by_match->{$match};

        if ( !defined($group) ) {
            my $class = $GROUP_ITEM{$query_type};

            $group = $class->new( { match => $match } );
            $self->group_by_match->{$match} = $group;

            push @{ $self->groups }, $group;
            push @{ $self->items },  $group;
        }

        $group->add_item($item);
    }
    else {
        push @{ $self->items }, $item;
    }
}

=method sort_items

Sort the result group by key.

=cut

sub sort_items {
    my $self = shift;

    foreach my $group ( @{ $self->groups } ) {
        $group->sort_items;
    }

    $self->_items( [ sort { $a->key cmp $b->key } @{ $self->items } ] );
}

no Moose;
__PACKAGE__->meta->make_immutable;
