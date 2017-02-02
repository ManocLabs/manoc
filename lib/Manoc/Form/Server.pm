package Manoc::Form::Server;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Horizontal';
with 'Manoc::Form::TraitFor::SaveButton';

use namespace::autoclean;
use Manoc::Form::Helper qw/bs_block_field_helper/;

has '+item_class' => ( default => 'Server' );

has '+name'        => ( default => 'form-server' );
has '+html_prefix' => ( default => 1 );

sub build_render_list {
    my $self = shift;

    return [
        'host_ip_block',
        'os_type_block',
        'vm_block',
        'serverhw_block',
        'virt_block',

        'save',
        'csrf_token',
    ];
}

has_block 'host_ip_block' => (
    render_list => [ 'hostname', 'address' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'hostname' => (
    type => 'Text',
    size => 128,
    required => 1,
    label => 'Hostname',
    element_attr => { placeholder => 'hostname.local.domain' },
    bs_block_field_helper({ label => 2, input => 4 })

);
has_field 'address' => (
    type => 'Text', size => 15, required => 1, label => 'IP Address',
    element_attr => { placeholder => 'leave empty to use DNS' },
    bs_block_field_helper({ label => 2, input => 4 })
);

has_block 'os_type_block' => (
    render_list => [ 'type', 'os', 'os_ver' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'type' => (
    type     => 'Select',
    required => 1,
    label    => 'Type',
    widget   => 'RadioGroup',
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
    bs_block_field_helper({ label => 2, input => 4 })
);

has_field 'os' => (
    type => 'Text', size => 32, label => 'OS Name',
    element_attr => { placeholder => 'e.g. CentOS' },

    bs_block_field_helper({ label => 1, input => 2 })
);

has_field 'os_ver' => (
    type => 'Text', size => 32, label => 'Version',
    element_attr => { placeholder => 'e.g. 7.0' },

    bs_block_field_helper({ label => 1, input => 2 })
);



has_block 'serverhw_block' => (
    render_list => [ 'serverhw', 'serverhw_btn' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'serverhw' => (
    type => 'Select',
    label => 'Hardware',
    bs_block_field_helper({ label => 2, input => 8 })
);


has_field 'serverhw_btn' => (
    type           => 'Button',
    widget         => 'ButtonTag',
    element_attr   => {
        class => [ 'btn', 'btn-primary' ],
        href => '#',
    },
    widget_wrapper => 'None',
    value          => "Add",
);

has_block 'vm_block' => (
    render_list => [ 'vm', 'vm_btn' ],
    tag         => 'div',
    class       => ['form-group'],
);


has_field 'vm' => (
    type => 'Select',
    label => 'Virtual Machine',
    bs_block_field_helper({ label => 2, input => 8 })
);


has_field 'vm_btn' => (
    type           => 'Button',
    widget         => 'ButtonTag',
    element_attr   => {
        class => [ 'btn', 'btn-primary' ],
        href => '#',
    },
    widget_wrapper => 'None',
    value          => "Add",
);


has_block 'virt_block' => (
    render_list => [ 'is_hypervisor', 'hosted_virtinfr' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'is_hypervisor' => (
    type     => 'Select',
    required => 1,
    label    => 'Hypervisor',
    widget   => 'RadioGroup',
    options  => [
        { value => 1, label => 'True'},
        { value => 0, label => 'False' }
    ],
    wrapper_tags => { inline => 1 },
    bs_block_field_helper({ label => 2, input => 2 })
);

has_field 'hosted_virtinfr' => (
    type => 'Select',
    label => 'Virtual Infrastructure',
    bs_block_field_helper({ label => 4, input => 4 })
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
    my @rs = $self->schema->resultset('VirtualMachine')
        ->unused()
        ->search({}, {
            prefetch => [ 'virtinfr', 'hypervisor' ]
        })->all();

    my @selections;
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
