# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in Manoc.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

Manoc::Controller::Root - Root Controller for Manoc

=head1 DESCRIPTION

The Root controller is used to implement global actions.

=head1 METHODS

=head2 index

The root page (/), redirect to search page.

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect($c->uri_for_action('/search/index'));
    $c->detach();
}

=head2 auto

Perform CSRF checks for POST requests, sets is_xhr for async request, check authentication.

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    # CSRF protection
    if ( $c->req->method eq 'POST' && !$c->stash->{skip_csrf}) {
        $c->log->debug("POST method, token validation required");
        $c->require_valid_token();
    }

    ##  XHR detection ##
    if (my $req_with =  $c->req->header('X-Requested-With')) {
        $c->stash->{is_xhr} = $req_with eq 'XMLHttpRequest';
    } else {
        $c->stash->{is_xhr} = 0;
    }

    ## output format selection ##
    if ( my $fmt = $c->req->param('format') ) {
        $fmt eq 'fragment' and $c->stash(no_wrapper => 1);
        delete $c->req->params->{'format'};
    }

    ## check authentication ##
    if (! $self->check_auth($c) ) {

        if ( $c->stash->{is_xhr} ) {
            $self->forward('error/http_403');
        } else {
            $c->flash( );
            $c->response->redirect(
                $c->uri_for_action('/auth/login', {
                    login_redirect => $c->request->path
                })
            );
        }
        return 0;
    }

    return 1;
}

sub check_auth {
    my ($self, $c) = @_;

    $c->config->{demo_mode}
        and return 1;

    $c->controller eq $c->controller('Auth')
        and return 1;

    $c->controller eq $c->controller('Wapi')
        and return 1;

    return $c->user_exists;
}

=head2 default

Shows 404 error page for Manoc using Error controller

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->detach('error/http_404');
}

=head2 message

Basic minimal page for showing messages

=cut

sub message : Path('message') Args(0) {
    my ( $self, $c ) = @_;
    my $page = $c->request->param('page');
    $c->stash( template => 'message.tt' );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
}

=head2 access_denied

Action called by ACL rules for failed checks.
Shows 403 error page for Manoc using Error controller


=cut

sub access_denied : Private {
    my ( $self, $c, $action ) = @_;
    $c->detach('error/http_403');
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
