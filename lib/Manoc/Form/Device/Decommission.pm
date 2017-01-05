# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Device::Decommission;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';

has '+name'        => ( default => 'form-decommission' );
has '+html_prefix' => ( default => 1 );

has_field 'decommission' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', ] },
    widget_wrapper => 'None',
    value          => "Decommission",
    order          => 1000,
);

has_field 'asset_action' => (
    label   => 'Action for associated hardware',
    type    => 'Select',
    widget  => 'RadioGroup',
    options => [
        { value => 'DECOMMISSION',   label => 'Decommission' },
        { value => 'WAREHOUSE', label => 'Return to warehouse' },
    ],
);

sub update_model {
    my $self   = shift;
    my $values = $self->values;

    my $device  = $self->item;
    my $hwasset = $device->hwasset;

    $self->schema->txn_do(
        sub {
            if ($hwasset) {
                my $action = $values->{asset_action};
                $action eq 'DECOMMISSION' and
                    $hwasset->decommission();
                $action eq 'WAREHOUSE' and
                    $hwasset->in_warehouse(1);
                $hwasset->update();
            }

            $device->decommission();
            $device->update;
        }
    );
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
