# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Device::Dismiss;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';

has '+name'        => ( default => 'form-dismiss' );
has '+html_prefix' => ( default => 1 );

has_field 'dismiss' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', ] },
    widget_wrapper => 'None',
    value          => "Dismiss",
    order          => 1000,
);

has_field 'asset_action' => (
    label   => 'Action for associated hardware',
    type    => 'Select',
    widget  => 'RadioGroup',
    options => [
        { value => 'DISMISS',  label => 'Dismiss' },
        { value => 'WAREHOUSE', label => 'Return to warehouse' },
    ],
);

sub update_model {
    my $self   = shift;
    my $values = $self->values;

    $self->schema->txn_do(
        sub {
            my $device = $self->item;
            $device->dismissed(1);


            if (my $hwasset = $device->hwasset) {
                my $action = $values->{asset_action};
                $action eq 'DISMISS' and
                    $hwasset->dismiss(1);
                $action eq 'WAREHOUSE' and
                    $hwasset->in_warehouse(1);
                $hwasset->update();

                $device->hwasset(undef);
            }

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
