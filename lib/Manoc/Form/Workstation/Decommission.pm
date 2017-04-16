# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Workstation::Decommission;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Theme';

has '+name'        => ( default => 'form-workstation-decommission' );
has '+html_prefix' => ( default => 1 );

has_field 'submit' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', ] },
    widget_wrapper => 'None',
    value          => "Decommission",
    order          => 1000,
);

has_field 'hardware_action' => (
    label   => 'Action for associated hardware',
    type    => 'Select',
    widget  => 'RadioGroup',
    options => [
        { value => 'DECOMMISSION', label => 'Decommission' },
        { value => 'WAREHOUSE',    label => 'Return to warehouse' },
    ],
);

sub build_render_list {
    my $self = shift;

    return unless $self->item;

    my $workstation = $self->item;
    my @list;

    $workstation->workstationhw and
        push @list, 'hardware_action';

    push @list, "submit", "csrf_token";

    return \@list;
}

before update_fields => sub {
    my $self = shift;
    return unless $self->item;

    my $workstation = $self->item;

    $workstation->workstationhw and
        $self->field('hardware_action')->required(1);
};

sub update_model {
    my $self   = shift;
    my $values = $self->values;

    my $workstation = $self->item;
    my $hardware    = $workstation->workstationhw;

    $self->schema->txn_do(
        sub {
            if ($hardware) {
                my $action = $values->{hardware_action};
                if ( $action eq 'DECOMMISSION' ) {
                    $hardware->decommission();
                }
                elsif ( $action eq 'WAREHOUSE' ) {
                    $hardware->move_to_warehouse();
                }
                else {
                    die "Something terrible wrong with this form";
                }
                $hardware->update();

            }

            $workstation->decommission();
            $workstation->update;
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
