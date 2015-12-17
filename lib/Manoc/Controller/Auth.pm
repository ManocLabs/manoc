# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Auth;
use Moose;
use namespace::autoclean;
use Manoc::Form::Login;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Auth - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.


=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/auth/login') );
    $c->detach();
}

=head2 login

=cut

sub login : Local : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    
    my $login_redirect = $c->req->params()->{login_redirect};
    my $redirect = $login_redirect
	? $c->base . '/' . $login_redirect
	: $c->uri_for('/search');

    my $form = Manoc::Form::Login->new( ctx => $c );
    my $success = $form->process(
	posted => ($c->req->method eq 'POST'),
	params => $c->req->params );

    if ( $success ) {
	my $username = $c->user->username;
	$c->log->info( 'User ' . $username . ' logged');
	$c->response->redirect($redirect);
    }

    $c->stash(
	form => $form,
	template => 'auth/login.tt',
    );
}

=head2 logout

=cut

sub logout : Local : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->logout();
    $c->delete_session();
    $c->response->redirect($c->uri_for('/auth/login'));
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
