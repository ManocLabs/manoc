package App::Manoc::Form::DeviceIface::Populate;
#ABSTRACT: Manoc Form for entering interface notes.

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';

has '+name' => ( default => 'form-ifnotes' );

has 'schema' => ( is => 'rw' );

has 'device' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
    trigger  => sub { shift->set_device(@_) }
);

sub set_device {
    my ( $self, $device ) = @_;
    $self->schema( $device->result_source->schema );
}

has_field 'prefix' => (
    label    => 'Prefix',
    type     => 'Text',
    required => 1,
);

has_field 'range_min' => (
    label    => 'Min',
    type     => 'Text',
    required => 1,
);

has_field 'range_max' => (
    label    => 'Max',
    type     => 'Text',
    required => 1,
);

has_field 'save' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', 'btn-primary' ] },
    widget_wrapper => 'None',
    value          => "Save"
);

sub update_model {
    my $self = shift;

    my $device = $self->device;

    my $prefix = $self->value->{prefix};
    my $min    = $self->value->{range_min};
    my $max    = $self->value->{range_max};

    $self->schema->txn_do(
        sub {
            for ( my $i = $min; $i <= $max; $i++ ) {
                $device->add_to_interfaces( { name => "$prefix$i" } );
            }
        }
    );
}
__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
