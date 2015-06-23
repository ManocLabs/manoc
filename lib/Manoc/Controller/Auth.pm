# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Auth;
use Moose;
use namespace::autoclean;

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

    my $username = $c->req->params->{'username'};
    my $password = $c->req->params->{'password'};

    $c->stash( template => 'auth/login.tt' );
    $c->keep_flash("backref");

    $c->stash( default_backref => $c->uri_for('/search') );

    if ( defined( $username ) ) {
	my $userinfo = {
	    username => $username,
	    password => $password,
	};
        if ($c->authenticate($userinfo) ) {
            $c->flash( message => 'Logged In!' );
            $c->log->debug( 'User ' . $username . ' logged');
            $c->detach('/follow_backref');
        }
        else {
            $c->flash( error_msg => 'Invalid Login' );
            $c->response->redirect( $c->uri_for('/auth/login') );
            $c->detach();
        }
    }
}

=head2 logout

=cut

sub logout : Local : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash( template => 'auth/logout.tt' );

    $c->logout();
    $c->delete_session();
    $c->stash( message => 'You have been logged out.' );
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
