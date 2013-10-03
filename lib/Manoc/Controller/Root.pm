# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

with 'Manoc::BackRef::Actions';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

Manoc::Controller::Root - Root Controller for Manoc

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect($c->uri_for_action('/search'));
    $c->detach();
}

=head2 auto


=cut

sub auto : Private {
  my ( $self, $c ) = @_;

  ##  XHR detection ##
  if (my $req_with =  $c->req->header('X-Requested-With')) {
      $c->stash->{is_xhr} = $req_with eq 'XMLHttpRequest';
  } else {
      $c->stash->{is_xhr} = 0;
  }

  ## output format selection ##
  if ( my $fmt = $c->req->param('format') ) {
      $fmt eq 'popup'    and $c->stash('current_view' => 'PopupPage');
      $fmt eq 'fragment' and $c->stash('current_view' => 'HTMLFragment');

      delete $c->req->params->{'format'};
  }


  ## redirect to login if needed ##
  my $skip_login_redirect;
  if ( $c->stash->{is_xhr} ||
         $c->controller eq $c->controller('Auth') ||
           $c->controller eq $c->controller('Wapi') ) {
      $skip_login_redirect = 1;
  }

  # If a user doesn't exist, force login
  if ( !$c->user_in_realm('normal') && !$skip_login_redirect ) {
    $c->flash( backref => $c->request->uri );
    $c->response->redirect( $c->uri_for('/auth/login') );
    return 0;
  }

  return 1;
}


=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    my $url = $c->request->uri;
    $c->response->body("Page not found $url");
    
    $c->response->status(404);
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

=cut

sub access_denied : Private {
    my ( $self, $c ) = @_;
    $c->flash( backref => $c->req->uri );
    $c->stash( template  => 'auth/access_denied.tt' );
    $c->stash( error_msg => "Sorry, you are not allowed to see this page!" );
}

=head1 AUTHOR

gabriele

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
