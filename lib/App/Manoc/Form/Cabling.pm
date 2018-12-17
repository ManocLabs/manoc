package App::Manoc::Form::Cabling;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';

has '+name' => ( default => 'form-devcabling' );

# has 'schema' => ( is => 'rw' );

has_field 'interface1' => (
    type         => 'Select',
    empty_select => '--- Select ---',
    required     => 1,
    do_wrapper   => 0,
);

has_field 'interface2' => (
    type         => 'Select',
    empty_select => '--- Select ---',
    required     => 0,
    do_wrapper   => 0,
);

has_field 'serverhw_nic' => (
    type         => 'Select',
    empty_select => '--- Select ---',
    required     => 0,
    do_wrapper   => 0,
);

has_field 'save' => (
    type  => 'Submit',
    value => "Save"
);

has 'interface1_obj' => (
    isa => 'Object',
    is  => 'rw',
);

has 'interface1_obj' => (
    isa => 'Object',
    is  => 'rw',
);

has 'interface2_obj' => (
    isa => 'Object',
    is  => 'rw',
);

has 'serverhw_nic_obj' => (
    isa => 'Object',
    is  => 'rw',
);

sub validate_interface1 {
    my ( $self, $field ) = @_;

    my $id = $self->field('interface1')->value;
    defined($id) or return;

    my $interface = $self->schema->resultset('DeviceIface')->find($id);

    if ($interface) {
        $self->interface1_obj($interface);
    }
    else {
        $field->add_error("Interface not found");
    }
}

sub validate_interface2 {
    my ( $self, $field ) = @_;

    my $id = $self->field('interface2')->value;
    defined($id) or return;

    my $interface = $self->schema->resultset('DeviceIface')->find($id);
    if ($interface) {
        $self->interface2_obj($interface);
    }
    else {
        $field->add_error("Interface not found");
    }
}

sub validate_serverhw_nic {
    my ( $self, $field ) = @_;

    my $id = $self->field('serverhw_nic')->value;
    defined($id) or return;

    my $nic = $self->schema->resultset('ServerHWNIC')->find($id);
    if ($nic) {
        $self->serverhw_nic_obj($nic);
    }
    else {
        $field->add_error("NIC not found");
    }
}

override validate_model => sub {
    my $self = shift;

    super();

    if ( !defined( $self->interface2_obj ) && !defined( $self->serverhw_nic_obj ) ) {
        $self->add_form_error('Missing destination');
    }

    if ( defined( $self->interface2_obj ) ) {
        if ( $self->interface1_obj->device_id == $self->interface2_obj->device_id ) {
            $self->add_form_error(
                'Loop detected: both source and destination on the same device');
        }
    }
};

override update_model => sub {
    my $self   = shift;
    my $values = $self->values;

    $self->schema->txn_do(
        sub {
            if ( $self->interface2_obj ) {
                $self->interface1_obj->add_cabling_to_interface( $self->interface2_obj );
            }
            if ( $self->serverhw_nic_obj ) {
                $self->interface1_obj->add_cabling_to_nic( $self->serverhw_nic_obj );
            }
        }
    );
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
