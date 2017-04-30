package App::Manoc::Form::Device::Decommission;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';

has '+name'        => ( default => 'form-decommission' );
has '+html_prefix' => ( default => 1 );

has_field 'submit' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', ] },
    widget_wrapper => 'None',
    value          => "Decommission",
    order          => 1000,
);

has_field 'asset_action' => (
    label    => 'Action for associated hardware',
    type     => 'Select',
    widget   => 'RadioGroup',
    required => 1,
    options  => [
        { value => 'DECOMMISSION', label => 'Decommission' },
        { value => 'WAREHOUSE',    label => 'Return to warehouse' },
    ],
);

sub update_model {
    my $self   = shift;
    my $values = $self->values;
    my $action = $values->{asset_action};

    my $device  = $self->item;
    my $hwasset = $device->hwasset;

    $self->schema->txn_do(
        sub {
            if ($hwasset) {
                $action eq 'DECOMMISSION' and
                    $hwasset->decommission();
                $action eq 'WAREHOUSE' and
                    $hwasset->move_to_warehouse();
                $hwasset->update();
            }

            $device->decommission();
            $device->update;
        }
    );
    return $device;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
