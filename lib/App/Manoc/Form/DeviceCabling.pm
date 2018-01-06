package App::Manoc::Form::DeviceCabling;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';

has '+name'        => ( default => 'form-devcabling' );
has '+html_prefix' => ( default => 1 );

has 'schema' => ( is => 'rw' );

has 'device1' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

has_field 'interface1' => (
    type         => 'Select',
    label        => 'Interface1',
    empty_select => '--- Select ---',
    required     => 0,
    do_wrapper   => 0,
);

has_field 'device2' => (
    type          => 'Select',
    label         => 'Interface1',
    empty_select  => '--- Select ---',
    required      => 0,
    element_class => 'selectpicker',
    do_wrapper    => 0,
);

has_field 'interface2' => (
    type         => 'Select',
    label        => 'Interface1',
    empty_select => '--- Select ---',
    required     => 0,
    do_wrapper   => 0,

);

has_field 'hwserver_nic' => (
    type         => 'Select',
    label        => 'Interface1',
    empty_select => '--- Select ---',
    required     => 0,
    do_wrapper   => 0,
);

has_field 'save' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', 'btn-primary' ] },
    widget_wrapper => 'None',
    value          => "Save"
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
