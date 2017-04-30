package App::Manoc::Form::TraitFor::SaveButton;
#ABSTRACT: Role for adding a BS3 'Save' button

use HTML::FormHandler::Moose::Role;

##VERSION

=head1 DESCRIPTION

Include this role to add a Bootstrap 3 submit button labeled 'Save'

=head1 FIELDS

=head2 save

The save button itself. Order is set to 1000 to make sure it is always at the bottom of the form.

=cut

has_field 'save' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', 'btn-primary' ] },
    widget_wrapper => 'None',
    value          => "Save",
    order          => 1000,
);

no HTML::FormHandler::Moose::Role;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
