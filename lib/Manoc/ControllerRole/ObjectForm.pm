# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ControllerRole::ObjectForm;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

with 'Manoc::ControllerRole::Object';

has 'form_class' => (
    is  => 'rw',
    isa => 'ClassName'
);

=head1 ACTIONS

=head2 form

Handle creation and editing of resources. Form defaults can be
injected using form_defaults in stash. Form is created by get_form method.

=cut

sub form : Private {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{object};
    my $form = $self->get_form($c);

    $c->stash(
        form   => $form,
        action => $c->uri_for($c->action, $c->req->captures),
    );
    unless ( $c->stash->{template} ) {
        $c->stash(template =>  $c->namespace . "/form.tt" );
    }

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened
    my %process_params;
    $process_params{item}   =  $c->stash->{object};
    $process_params{params} =  $c->req->parameters;
    if ( $c->stash->{form_defaults} ) {
        $process_params{defaults} = $c->stash->{form_defaults};
        $process_params{use_defaults_over_obj} = 1;
    }
    return unless $form->process( %process_params );

    $c->stash(message => $self->object_updated_message );
    if ($c->stash->{is_xhr}) {
        $c->stash(no_wrapper => 1);
        $c->stash(template   => 'dialog/message.tt');
        return;
    }

    $c->res->redirect( $self->get_form_success_url($c) );
    $c->detach();
}

=head1 METHODS

=head2 get_form

Create a new form using form_class configuration parameter.

=cut

sub get_form {
    my ($self, $c) = @_;

    my $class = $self->form_class;
    $class or die "Form class not set (use form_class)";
    return $class->new(ctx => $c);
}

=head2 get_form_success_url

Get the URL to redirect after successful editing.

=cut

sub get_form_success_url {
    my ($self, $c) = @_;
    return $c->uri_for_action($c->namespace . "/list");
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
