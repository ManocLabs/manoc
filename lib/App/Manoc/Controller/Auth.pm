package App::Manoc::Controller::Auth;
#ABSTRACT: Auth Catalyst Controller

use Moose;

##VERSION

use namespace::autoclean;
use App::Manoc::Form::Login;

BEGIN { extends 'Catalyst::Controller'; }

=action index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/auth/login') );
    $c->detach();
}

=action login

=cut

sub login : Local : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my $login_redirect = $c->req->params()->{login_redirect};
    my $redirect =
        $login_redirect ? $c->req->base . $login_redirect :
        $c->uri_for('/search');

    my $form = App::Manoc::Form::Login->new( ctx => $c );
    my $success = $form->process(
        posted => ( $c->req->method eq 'POST' ),
        params => $c->req->params
    );

    if ($success) {
        my $username = $c->user->username;
        $c->log->info( 'User ' . $username . ' logged' );
        $c->response->redirect($redirect);
    }

    $c->stash(
        form     => $form,
        template => 'auth/login.tt',
    );
}

=action logout

=cut

sub logout : Local : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->logout();
    $c->delete_session();
    $c->response->redirect( $c->uri_for('/auth/login') );
}

__PACKAGE__->meta->make_immutable;

1;
