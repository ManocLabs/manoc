# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item;
use Moose;
use namespace::autoclean;

with 'Manoc::Search::Widget::ApplyRole';

has 'item_type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

# unixtime
has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has 'match' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'key' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_key',
);

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

sub _build_key { $_[0]->match }

has widget => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { [ split( /::/, ref( $_[0] ) ) ]->[-1] }
);

sub load_widgets {
    my $self = shift;

    $self->apply_widget_role( $self, $self->widget );
}

no Moose;
__PACKAGE__->meta->make_immutable;
