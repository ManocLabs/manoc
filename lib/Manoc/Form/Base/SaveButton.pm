# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Base::SaveButton;
use HTML::FormHandler::Moose::Role;

=head1 NAME

Manoc::Form::Base::Horizontal - Role for adding a BS3 'Save' button

=head1 DESCRIPTION

Include this role to add a Bootstrap 3 submit button labeled 'Save'

=head1 FIELDS

=head2 save

The save button itself. Order is set to 1000 to make sure it is always at the bottom of the form.

=cut

has_field 'save' => (
    type => 'Submit',
    widget => 'ButtonTag',
    element_attr => { class => ['btn', 'btn-primary'] },
    widget_wrapper => 'None',
    value => "Save",
    order => 1000,
);

=head1 AUTHOR

Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no HTML::FormHandler::Moose::Role;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
