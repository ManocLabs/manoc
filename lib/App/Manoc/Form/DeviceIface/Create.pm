package App::Manoc::Form::DeviceIface::Create;
#ABSTRACT: Manoc Form for entering interface notes.

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';

has '+name' => ( default => 'form-ifnotes' );

has 'device_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has_field 'name' => (
    label    => 'Name',
    type     => 'Text',
    required => 1,
);

has_field 'routed' => (
    label => 'Routed',
    type  => 'Checkbox',
);

has_field 'notes' => (
    type  => 'TextArea',
    label => 'Notes',
);

has_field 'save' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', 'btn-primary' ] },
    widget_wrapper => 'None',
    value          => "Save"
);

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    $values->{device_id} = $self->{device_id};
    $self->_set_value($values);

    super();
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
