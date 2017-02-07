# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Login;
use utf8;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler';
with 'Manoc::Form::TraitFor::Theme';
with 'Manoc::Form::TraitFor::CSRF';

has '+name' => ( default => 'login_form' );

sub build_do_form_wrapper    { 0 }
sub build_form_wrapper_class { [] }
sub build_form_element_class { ['form-vertical'] }

sub build_render_list {
    [ 'fieldset', 'submit', 'csrf_token' ];
}

has_block 'fieldset' => (
    tag         => 'fieldset',
    render_list => [ 'username', 'password' ],
    tag         => 'fieldset',
);

has 'login_error_message' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'Wrong username or password',
);

has_field 'username' => (
    type         => 'Text',
    required     => 1,
    do_label     => 0,
    element_attr => { placeholder => 'Username' },
);
has_field 'password' => (
    type         => 'Password',
    required     => 1,
    do_label     => 0,
    element_attr => { placeholder => 'Password' },
);

has_field 'submit' => (
    type         => 'Submit',
    value        => 'Login',
    widget       => 'ButtonTag',
    do_wrapper   => 0,
    element_attr => { class => [qw"btn btn-lg btn-success btn-block"] },
);

sub validate {
    my $self = shift;

    my $username  = $self->values->{username};
    my $password  = $self->values->{password};
    my $auth_info = {
        username => $username,
        password => $password
    };
    unless ( $self->ctx->authenticate($auth_info) ) {
        $self->field('password')->add_error( $self->login_error_message );
    }
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
