package Manoc::Form::DHCPSubnet;

use HTML::FormHandler::Moose;

use namespace::autoclean;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::Horizontal';

use HTML::FormHandler::Types ('IPAddress');

sub build_render_list {
    [
        'name',
        'dhcp_server',
        'dhcp_shared_network',
        'network',
        'range_block',
        'max_lease_time',
        'default_lease_time',
        'ntp_server',
        'domain_name',
        'domain_nameserver',
        'save',
        'csrf_token'
    ];
}

has '+name'        => ( default => 'form-dhcpsubnet' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'DHCPSubnet' );

has_field 'name' => (
    type => 'Text',
    required => 1,
    label => 'Name',
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'dhcp_server' => (
    type => 'Hidden',
);

has_field 'dhcp_shared_network' => (
    type => 'Select',
    label => 'Shared Network',
    empty_select => '--- No shared subnet ---',
);

has_field 'network' => (
    type => 'Select',
    label => 'Subnet',
    empty_select => '--- Select a subnet ---',
);

has_block 'range_block' => (
    render_list => [ 'range', 'ipblock_button' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'range' => (
    type => 'Select',
    label => 'IP Pool',
    empty_select => '--- Select Ip Pool ---',
    do_wrapper => 0,
    tags => {
        before_element => '<div class="col-sm-8">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);

has_field 'ipblock_button' => (
    type           => 'Button',
    widget         => 'ButtonTag',
    element_attr   => {
        class => [ 'btn', 'btn-primary' ],
        href => '#',
    },
    widget_wrapper => 'None',
    value          => "Add",
);

has_field 'max_lease_time' => (
    type => 'Integer',
    label => 'Maximum Lease Time',
);

has_field 'default_lease_time' => (
    type => 'Integer',
    label => 'Default Lease Time',
);

has_field 'ntp_server' => (
    type => 'Text',
    size => 15,
    apply      => [IPAddress],
    label => 'Ntp Server',
);

has_field 'domain_nameserver' => (
    type   => 'Text',
    size   =>  15,
    apply  => [IPAddress],
    label  => 'Domain Nameserver',
);

has_field 'domain_name' => (
    type => 'Text',
    label => 'Domain Name',
);

override validate_model => sub {
    my $self   = shift;
    my $item   = $self->item;
    my $values = $self->values;

    super();

    my $network = $self->schema->resultset('IPNetwork')
        ->find($values->{network});
    my $range = $self->schema->resultset('IPBlock')
        ->find($values->{range});

    if ($range && $network) {
        if ( !$network->network->contains_address($range->from_addr) ||
                 !$network->network->contains_address($range->to_addr) )
            {
                $self->field('range')->add_error('Pool must be inside network')
            }
    }

};


sub options_dhcp_shared_network {
    my $self = shift;

    return unless $self->schema;

    my $server_id =
        ($self->item && $self->item->in_storage)
        ? $self->item->dhcp_server_id
        : $self->field('dhcp_server')->default;

    my $rs = $self->schema->resultset('DHCPSharedNetwork')->search(
        { dhcp_server_id => $server_id });

    return map +{ value => $_->id, label => $_->name }, $rs->all;
}

sub options_network {
    my $self = shift;

    return unless $self->schema;

    my $server_id;
    my $item_id;

    if ($self->item && $self->item->in_storage) {
        $server_id = $self->item->dhcp_server_id;
        $item_id   = $self->item->id;
    } else {
        $self->field('dhcp_server')->default;
    }


    my $server_network_ids =
        $self->resultset('DHCPSubnet')
        ->search(
            {
                dhcp_server_id => $server_id,
                -not => { id => $item_id },
            },
            {
                columns => [ 'network_id' ],
                distinct => 1
            });

    my $rs = $self->schema->resultset('IPNetwork')->search(
        {
           id => {  -not_in => $server_network_ids->as_query },
        });

    return map +{ value => $_->id, label => $_->label }, $rs->all();
}

before 'update_model' => sub {
    my $self = shift;

    if ($self->item->in_storage) {
        delete $self->values->{dhcp_server};
    }
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
