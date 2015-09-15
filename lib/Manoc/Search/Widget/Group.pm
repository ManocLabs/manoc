# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Widget::Group;
use Moose::Role;

sub render {
    my ($self, $ctx) = @_;

    my $ret = $self->render_heading($ctx);
    $ret .= $self->render_items($ctx);
    return $ret;
}

sub render_heading {
    my ($self, $ctx) = @_;
    return $self->match();
}

sub render_items {
    my ($self, $ctx) = @_;

    my $ret = '<ul>';
    foreach ( @{ $self->items } ) {
	$ret .= '<li>' . $_->render($ctx) . '</li>';
    }
    $ret .= '</ul>';

    return $ret;
}

no Moose::Role;
1;
