# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Widget::Iface;
use Moose::Role;

sub render {
    my ($self, $ctx) = @_;

    my $url = $ctx->uri_for_action('/interface/view', [ $device->device_id, $interface ]);
    return
	"<a href=\"$url\">" .
	$self->device_name . '/' . $self->interface .
	'</a>';
}

no Moose::Role;
1;
