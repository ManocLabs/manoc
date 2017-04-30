package App::Manoc::Search::Result;

use Moose;

##VERSION

use App::Manoc::Search::Item::IpAddr;
use App::Manoc::Search::Item::MacAddr;
use App::Manoc::Search::Item::WinLogon;
use App::Manoc::Search::Widget::ApplyRole;

has query => ( is => 'ro' );

has item_by_match => (
    is      => 'ro',
    isa     => 'HashRef[String]',
    default => sub { {} },
);

has message => (
    is  => 'rw',
    isa => 'Str',
);

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

sub items {
    my $self = shift;
    $self->sort_items;

    return $self->groups;
}

sub sort_items {
    my $self = shift;

    foreach my $group ( values %{ $self->item_by_match } ) {
        $group->sort_items;
    }

    my $groups = $self->groups;
    my @g = sort { $a->key cmp $b->key } @$groups;
    $self->_groups( \@g );
}

# use this method if
sub load_widgets {
    my $self = shift;

    foreach my $group ( values %{ $self->item_by_match } ) {
        $group->load_widgets(@_);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
