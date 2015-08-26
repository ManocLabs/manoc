# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Error;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Error

=head1 DESCRIPTION

Catalyst Controller for showing error pages

=head1 METHODS

=cut


=head2 http_403

Error page for HTTP 404.

=cut

sub http_403 : Private {
    my ( $self, $c ) = @_;
    $c->response->status(403);
    $c->stash( template => 'error_403.tt' );
    $c->response->status(404);
}

=head2 http_404

Error page for HTTP 404.

=cut

sub http_404 : Private {
    my ( $self, $c ) = @_;
    $c->stash( template => 'error_404.tt' );
    $c->response->status(404);
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
