# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with 'Manoc::ControllerRole::CommonCRUD' => {
    -excludes => 'view',
    };

use Manoc::Form::User;
use Manoc::Form::User::ChangePassword;

=head1 NAME

Manoc::Controller::User - Catalyst Controller

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
    class      => 'ManocDB::User',
    form_class => 'Manoc::Form::User',
);

=head1 METHODS

=cut

=head2 change_password

=cut

sub change_password : Chained('base') : PathPart('change_password') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(object => $c->user);
    my $form = Manoc::Form::User::ChangePassword->new({ctx => $c});

    $c->stash(
        form   => $form,
        action => $c->uri_for($c->action, $c->req->captures),
    );
    return unless $form->process(
        item   =>  $c->stash->{object},
        params =>  $c->req->parameters,
    );
    $c->detach();
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
