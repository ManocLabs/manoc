# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Result;
use Moose;

use Manoc::Search::Item::IpAddr;
use Manoc::Search::Item::MacAddr;
use Manoc::Search::Item::WinLogon;

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
    'logon'   => 'Manoc::Search::Item::WinLogon',
    'ipaddr'  => 'Manoc::Search::Item::IpAddr',
    'macaddr' => 'Manoc::Search::Item::MacAddr',
);

sub add_item {
    my ( $self, $item ) = @_;

    my $match = $item->match;

    my $query_type = $self->query->query_type;

    my $group = $self->item_by_match->{$match};
    if ( !defined($group) ) {
        my $class = $GROUP_ITEM{$query_type};
        $class ||= 'Manoc::Search::Item::Group';

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

no Moose;
__PACKAGE__->meta->make_immutable;
