package App::Manoc::Controller::Error;
#ABSTRACT: Error controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

App::Manoc::Controller::Error

=head1 DESCRIPTION

Catalyst Controller for showing error pages

=head1 METHODS

=cut

=head2 http_403

Error page for HTTP 403.

=cut

sub http_403 : Private {
    my ( $self, $c ) = @_;
    $c->stash( template => 'error_403.tt' );
    $c->response->status(403);
}

=head2 http_404

Error page for HTTP 404.

=cut

sub http_404 : Private {
    my ( $self, $c ) = @_;
    $c->stash( template => 'error_404.tt' );
    $c->response->status(404);
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
