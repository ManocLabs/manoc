package Manoc::Search::Widget::ApplyRole;

use Moose::Role;
use Class::Load qw/ load_optional_class /;
use namespace::autoclean;

sub apply_widget_role {
    my ( $self, $target, $widget_class ) = @_;

    my $render_role = $self->get_widget_role($widget_class);
    $render_role->meta->apply($target) if $render_role;
}

sub get_widget_role {
    my ( $self, $widget_class ) = @_;

    my @name_spaces = ( 'Manoc::Search::Widget', 'ManocX::Search::Widget' );
    my @classes;
    if ( $widget_class =~ s/^\+// ) {
        push @classes, $widget_class;
    }
    foreach my $ns (@name_spaces) {
        push @classes, $ns . '::' . $widget_class;
    }
    foreach my $try (@classes) {
        return $try if load_optional_class($try);
    }
    die "Can't find widget $widget_class from " . join( ", ", @name_spaces );
}

use namespace::autoclean;
1;
