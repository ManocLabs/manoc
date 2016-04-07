# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::User::Create;

use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';

with 'Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-user' );
has '+html_prefix' => ( default => 1 );

has_field 'username' => (
    type     => 'Text',
    label    => 'Username',
    required => 1,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /^\w[\w-]*$/ },
            message => 'Invalid Username'
        },
    ]
);

has_field 'password' => (
    type      => 'Password',
    label     => 'Password',
    required  => 1,
    minlength => 8,
);

has_field 'password2' => (
    type  => 'PasswordConf',
    label => 'Confirm Password',
);

has_field 'email' => (
    label => 'Email',
    type  => 'Email',
);

has_field 'fullname' => (
    type     => 'Text',
    required => 1,
);

has_field 'roles' => (
    type         => 'Multiple',
    label        => 'Roles',
    label_column => 'role',
);

has_field 'active' => (
    label   => 'Active',
    type    => 'Boolean',
    default => 1,
);

has_field 'superadmin' => (
    label => 'Active',
    type  => 'Boolean',
);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
