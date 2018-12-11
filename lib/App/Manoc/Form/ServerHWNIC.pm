package App::Manoc::Form::ServerHWNIC;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with
    'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::SaveButton';

use App::Manoc::Form::Types ('MacAddress');

has '+item_class' => ( default => 'ServerHWNIC' );
has '+name'       => ( default => 'form-serverhwnic' );

has_field 'name' => (
    type         => 'Text',
    size         => 32,
    element_attr => {
        placeholder => 'name',
    },

    label => 'NIC',
);

has_field 'nic_type' => (
    type         => 'Select',
    element_attr => {
        placeholder => 'type',
    },
);

has_field 'macaddr' => (
    type  => 'Text',
    apply => [MacAddress],

    label => 'MAC Address',

    element_attr => {
        placeholder => '00:00:00:00:00:00',
    },
);

has_field 'os_name' => (
    type         => 'Text',
    size         => 32,
    required     => 0,
    label        => 'OS Name',
    element_attr => {
        placeholder => 'NIC name as seen by the OS',
    },
);

has_field 'description' => (
    type => 'TextArea',
    size => 255,
);

has_field 'cabling_device' => (
    type                 => 'Select',
    empty_select         => '--- Select ---',
    required             => 0,
    noupdate             => 1,
    no_option_validation => 1,

);

has_field 'cabling_interface' => (
    type                 => 'Select',
    empty_select         => '--- Select ---',
    required             => 0,
    no_option_validation => 1,
);

has_field 'cabling_device_val' => (
    type     => 'Hidden',
    noupdate => 1,
);

has_field 'cabling_interface_val' => (
    type     => 'Hidden',
    noupdate => 1,
);

sub default_cabling_device_val {
    my ( $self, $field, $item ) = @_;

    $item or return;
    $item->cabling or return;
    return $item->cabling->interface1->device->id;
}

sub default_cabling_interface_val {
    my ( $self, $field, $item ) = @_;

    $item or return;
    $item->cabling or return;
    return $item->cabling->interface1->id;
}

sub options_nics_type {
    my $self = shift;
    return unless $self->schema;

    my @options;
    push @options,
        map +{
        value => $_->id,
        label => $_->name,
        },
        $self->schema->resultset('NICType')->all();

    return @options;
}

override 'update_model' => sub {
    my $self = shift;

    $self->schema->txn_do(
        sub {
            super();

            my $cabling          = $self->item->cabling;
            my $old_interface_id = $cabling ? $cabling->interface1->id : undef;
            my $new_interface_id = $self->value->{cabling_interface};

            if ( $cabling && $old_interface_id != $new_interface_id ) {
                $cabling->delete;
            }

            if ( !$cabling || $old_interface_id != $new_interface_id ) {
                my $fields = { interface1_id => $new_interface_id };
                $self->item->create_related( 'cabling', $fields );
            }
        }
    );
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
