# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Form::User::Edit;

use HTML::FormHandler::Moose;
extends 'App::Manoc::Form::Base';

with 'App::Manoc::Form::TraitFor::SaveButton';

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

has_field 'email' => (
    label => 'Email',
    type  => 'Email',
);

has_field 'fullname' => (
    type     => 'Text',
    required => 1,
);

has_field 'user_roles' => (
    type         => 'Multiple',
    label        => 'Roles',
    label_column => 'role',
);

has_field 'groups' => (
    type         => 'Multiple',
    label        => 'Groups',
    label_column => 'name',
);

has_field 'active' => (
    label => 'Active',
    type  => 'Boolean',
);

has_field 'superadmin' => (
    label => 'Admin',
    type  => 'Boolean',
);

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
