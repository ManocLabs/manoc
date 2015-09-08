# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Login;
use utf8;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler';
with 'Manoc::Form::Base::Theme';
with 'Manoc::Form::Base::CSRF';

has '+name' => ( default => 'login_form' );

has 'login_error_message' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => 'Wrong username or password',
);


has_field 'username' => ( type => 'Text', required => 1 );
has_field 'password' => ( type => 'Password', required => 1 );

has_field 'submit'   => (
    type => 'Submit',
    value => 'Login',
    widget => 'ButtonTag',
    element_attr => { class => ['btn', 'btn-primary'] },
);

sub validate {
    my $self = shift;

    my $username = $self->values->{username};
    my $password = $self->values->{password};
    my $auth_info = { username => $username,
		      password => $password
		  };
    unless ($self->ctx->authenticate($auth_info)) {
        $self->field( 'password' )->add_error( $self->login_error_message );
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
