package App::Manoc::Form::TraitFor::Actions;

use HTML::FormHandler::Moose::Role;

##VERSION

has_field 'form_actions' => (
    type           => 'Compound',
    order          => 99,
    widget_wrapper => 'Bootstrap',
    do_wrapper     => 1,
    do_label       => 0
);

has_field 'form_actions.save' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', 'btn-primary' ] },
    widget_wrapper => 'None',
    value          => "Save changes"
);

has_field 'form_actions.cancel' => (
    type           => 'Reset',
    widget         => 'ButtonTag',
    element_attr   => { class => ['btn'] },
    widget_wrapper => 'None',
    value          => "Reset"
);
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
