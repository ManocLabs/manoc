package App::Manoc::Search::Item;
#ABSTRACT: A search result item

use Moose;

##VERSION

use namespace::autoclean;

with 'App::Manoc::Search::Widget::ApplyRole';

=attr item_type

=cut

has 'item_type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

=attr timestamp

unixtime

=cut

has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

=attr match

=cut

has 'match' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=attr key

used for sorting, defaults to match

=cut

has 'key' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_key',
);

=attr text

=cut

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

sub _build_key { $_[0]->match }

=attr widget

Name of the widget to render this item.

=cut

has widget => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { [ split( /::/, ref( $_[0] ) ) ]->[-1] }
);

=method load_widgets

Load the widget and apply its role

=cut

sub load_widgets {
    my $self = shift;

    $self->apply_widget_role( $self, $self->widget );
}

no Moose;
__PACKAGE__->meta->make_immutable;
