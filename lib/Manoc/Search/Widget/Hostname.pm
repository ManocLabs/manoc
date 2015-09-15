# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Widget::Hostname;
use Moose::Role;

sub render {
    my ($self, $ctx) = @_;

    my $url = $ctx->uri_for_action('/ip/view', [ $self->ipaddr ]);
    return "<a href=\"$url\">" . $self->ipaddr . "</a>";
}

no Moose::Role;
1;
