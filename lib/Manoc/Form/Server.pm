package Manoc::Form::Server;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';

with 'Manoc::Form::TraitFor::SaveButton',
    'Manoc::Form::TraitFor::IPAddr';

use Manoc::Form::Types ('MacAddress');
use HTML::FormHandler::Types ('IPAddress');

use namespace::autoclean;

has '+item_class' => ( default => 'Server' );

has '+name'        => ( default => 'form-server' );
has '+html_prefix' => ( default => 1 );

has '+widget_wrapper' => ( default => 'None' );

has_field 'hostname' => (
    type         => 'Text',
    required     => 1,
    label        => 'Hostname',
    element_attr => {
        placeholder => 'hostname.local.domain',
        size         => '100%',
    },
);
has_field 'address' => (
    type         => 'Text',
    required     => 1,
    label        => 'Primary Address',
    apply        => [IPAddress],
    inflate_method => \&inflate_ipv4,
    element_attr => {
        placeholder => '0.0.0.0',
        size        => '100%',
    },

);

has_field 'type' => (
    type     => 'Select',
    required => 1,
    label    => 'Type',
    widget   => 'RadioGroup',
    noupdate => 1,
    options  => [
        {
            value => 'l',
            label => 'Logical'
        },
        {
            value => 'v',
            label => 'Virtual'
        },
        {
            value => 'p',
            label => 'Physical'
        },
    ],
    wrapper_tags => { inline => 1 },
);

has_field 'os' => (
    type         => 'Text',
    size         => 32,
    label        => 'OS Name',
    element_attr => { placeholder => 'e.g. CentOS' },
);

has_field 'os_ver' => (
    type         => 'Text',
    size         => 32,
    label        => 'Version',
    element_attr => { placeholder => 'e.g. 7.0' },
);

has_field 'serverhw' => (
    type         => 'Select',
    label        => 'Hardware',
    empty_select => '--- Choose ---',
);

has_field 'vm' => (
    type         => 'Select',
    label        => 'Virtual Machine',
    empty_select => '--- Choose ---',
);

has_field 'vm_btn' => (
    type         => 'Button',
    widget       => 'ButtonTag',
    element_attr => {
        class => [ 'btn', 'btn-primary' ],
        href  => '#',
    },
    widget_wrapper => 'None',
    value          => "Add",
);

has_field 'is_hypervisor' => (
    type     => 'Select',
    required => 1,
    label    => 'Hypervisor',
    widget   => 'RadioGroup',
    options  => [ { value => 1, label => 'True' }, { value => 0, label => 'False' } ],
    wrapper_tags => { inline => 1 },
);

has_field 'virtinfr' => (
    type         => 'Select',
    label        => 'Virtual Infrastructure',
    empty_select => '--- Choose ---',
);

has_field 'addresses' => (
    type       => 'Repeatable',
    do_wrapper => 0,
    add_extra  => 1,
);

has_field 'addresses.id' => (
    type => 'PrimaryKey'
);

has_field 'addresses.ipaddr' => (
    type         => 'Text',
    label        => 'IP Address',
    apply        => [IPAddress],
    inflate_method => \&inflate_ipv4,
    element_attr => {
        placeholder => '0.0.0.0',
    },
);

sub default_type {
    my $self = shift;

    return unless $self->schema;

    return 'v' if $self->item->vm;
    return 'p' if $self->item->serverhw;
    return 'l';
}

sub options_serverhw {
    my $self = shift;

    return unless $self->schema;
    my @rs = $self->schema->resultset('ServerHW')->unused()->all();
    my @selections;

    if ( my $s = $self->item->serverhw ) {
        push @selections,
            {
            label => $s->label,
            value => $s->id
            };
    }

    foreach my $b (@rs) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }

    return @selections;

}

sub options_vm {
    my $self = shift;

    return unless $self->schema;

    my @selections;

    if ( my $vm = $self->item->vm ) {
        push @selections,
            {
            label => $vm->label,
            value => $vm->id
            };
    }

    my @rs = $self->schema->resultset('VirtualMachine')->unused()->search(
        {},
        {
            prefetch => [ 'virtinfr', 'hypervisor' ]
        }
    )->all();
    foreach my $b (@rs) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;

}



__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
