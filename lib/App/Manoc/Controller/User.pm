# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with 'App::Manoc::ControllerRole::CommonCRUD' => { -excludes => 'view', };

use App::Manoc::Form::User::Create;
use App::Manoc::Form::User::Edit;
use App::Manoc::Form::User::ChangePassword;
use App::Manoc::Form::User::SetPassword;

=head1 NAME

App::Manoc::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'user',
        }
    },
    class                   => 'ManocDB::User',
    create_form_class       => 'App::Manoc::Form::User::Create',
    edit_form_class         => 'App::Manoc::Form::User::Edit',
    enable_permission_check => 1,
);

=head1 METHODS

=cut

=head2 admin_password

Used by admin to set password on other users

=cut

sub admin_password : Chained('object') : PathPart('password') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = App::Manoc::Form::User::SetPassword->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    if (
        $form->process(
            item   => $c->stash->{object},
            params => $c->req->parameters
        )
        )
    {
        $c->log->debug("password changed") if $c->debug;
        $c->res->redirect( $c->uri_for_action('user/list') );
    }
}

=cut

=head2 change_password

=cut

sub change_password : Chained('base') : PathPart('password') : Args(0) {
    my ( $self, $c ) = @_;

    # no permission required
    $c->stash( object => $c->user );
    my $form = App::Manoc::Form::User::ChangePassword->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );
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
