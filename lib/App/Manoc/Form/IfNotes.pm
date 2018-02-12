package App::Manoc::Form::IfNotes;
#ABSTRACT: Manoc Form for entering interface notes.

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';

has '+name' => ( default => 'form-ifnotes' );

has 'device' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'interface' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
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

    if ( $values->{notes} =~ /^\s*$/o && $self->item->in_storage ) {
        $self->item->delete();
        return 1;
    }

    $values->{device}    = $self->{device};
    $values->{interface} = $self->{interface};    #
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
