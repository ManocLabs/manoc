# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Widget::Rack;
use Moose::Role;

sub render {
    my ($self, $ctx) = @_;

    my $url = $ctx->uri_for_action('/rack/view', [ $self->id ]);
    return "<a href=\"$url\">" . $self->name . '</a>';
}

no Moose::Role;
1;
