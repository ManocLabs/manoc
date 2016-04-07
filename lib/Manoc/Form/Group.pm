# Copyright 2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Form::Group;
use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';
use namespace::autoclean;

with 'Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-user' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'Group' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Name',
);

has_field 'description' => (
    type  => 'TextArea',
    label => 'description',
);

has_field 'roles' => (
    type         => 'Multiple',
    label        => 'Roles',
    label_column => 'role',
);

has_field 'users' => (
    type         => 'Multiple',
    label        => 'Users',
    label_column => 'username',
);

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
