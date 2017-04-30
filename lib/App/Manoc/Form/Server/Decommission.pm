package App::Manoc::Form::Server::Decommission;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::Theme';

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
    label   => 'Action for associated hardware',
    type    => 'Select',
    widget  => 'RadioGroup',
    options => [
        { value => 'DECOMMISSION', label => 'Decommission' },
        { value => 'WAREHOUSE',    label => 'Return to warehouse' },
    ],
);

has_field 'vm_action' => (
    label   => 'Action for associated virtual machine',
    type    => 'Select',
    widget  => 'RadioGroup',
    options => [
        { value => 'DECOMMISSION', label => 'Decommission' },
        { value => 'KEEP',         label => 'Deassociate' },
    ],
);

has_field 'hostedvm_action' => (
    label   => 'Action for hosted virtual machine',
    type    => 'Select',
    widget  => 'RadioGroup',
    options => [
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
    $server->virtual_machines->count and
        push @list, 'hostedvm_action';
    push @list, "submit", "csrf_token";

    return \@list;
}

before update_fields => sub {
    my $self = shift;
    return unless $self->item;

    my $server = $self->item;

    $server->serverhw and
        $self->field('serverhw_action')->required(1);

    $server->vm and
        $self->field('vm_action')->required(1);

    $server->virtual_machines->count and
        $self->field('hostedvm_action')->required(1);
};

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

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
