# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Server::Decommission;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Theme';

has '+name'        => ( default => 'form-server-decommission' );
has '+html_prefix' => ( default => 1 );

has_field 'submit' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', ] },
    widget_wrapper => 'None',
    value          => "Decommission",
    order          => 1000,
);

has_field 'serverhw_action' => (
    label    => 'Action for associated hardware',
    type     => 'Select',
    widget   => 'RadioGroup',
    required => 1,
    options  => [
        { value => 'DECOMMISSION', label => 'Decommission' },
        { value => 'WAREHOUSE',    label => 'Return to warehouse' },
    ],
);

has_field 'vm_action' => (
    label    => 'Action for associated virtual machine',
    type     => 'Select',
    widget   => 'RadioGroup',
    required => 1,
    options  => [
        { value => 'DECOMMISSION', label => 'Decommission' },
        { value => 'KEEP',         label => 'Deassociate' },
    ],
);

has_field 'hostedvm_action' => (
    label    => 'Action for hosted virtual machine',
    type     => 'Select',
    widget   => 'RadioGroup',
    required => 1,
    options  => [
        { value => 'KEEP',      label => 'Deassociate' },
        { value => 'RECURSIVE', label => 'Decommission VMs and servers' },
    ],
);

sub build_render_list {
    my $self = shift;

    return unless $self->item;

    my $server = $self->item;
    my @list;

    $server->serverhw and
        push @list, 'serverhw_action';
    $server->vm and
        push @list, 'vm_action';
    $server->virtual_machines and
        push @list, 'hostedvm_action';
    push @list, "submit", "csrf_token";

    return \@list;
}

sub update_model {
    my $self   = shift;
    my $values = $self->values;

    my $server = $self->item;
    my $hw     = $server->serverhw;
    my $vm     = $server->vm;

    $self->schema->txn_do(
        sub {
            if ($hw) {
                my $action = $values->{serverhw_action};
                $action eq 'DECOMMISSION' and
                    $hw->decommission();
                $action eq 'WAREHOUSE' and
                    $hw->move_to_warehouse();
                $hw->update();

            }

            if ($vm) {
                my $action = $values->{vm_action};
                $action eq 'DECOMMISSION' and
                    $vm->decommission;
                $vm->update();
            }

            my $recursive = 0;
            if ( $server->virtual_machines ) {
                my $action = $values->{hostedvm_action};
                $recursive = defined($action) && $action eq 'RECURSIVE';
            }

            $server->decommission( recursive => $recursive );
            $server->update;
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
