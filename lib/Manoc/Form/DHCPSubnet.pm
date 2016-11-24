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
        'dhcp_shared_subnet',
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
    type => 'Select', 
    label => 'DHCP Server', 
);

has_field 'dhcp_shared_subnet' => ( 
    type => 'Select', 
    label => 'Shared Subnet', 
    empty_select => 'No shared subnet', 
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
    type => 'Text',
    size => 15, 
    apply      => [IPAddress],
    label => 'Domain Nameserver', 
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
    
   #TODO contollo che gli indirizzi from e to ricadino nella subnet associata
 

};

sub options_network {
    my $self = shift;

    return unless $self->schema;
    my $rs = $self->schema->resultset('IPNetwork')->search( { 'dhcp_subnet.id' => undef }, {  join => 'dhcp_subnet' , prefetch => 'dhcp_subnet', order_by => 'address'} );

    return map +{ value => $_->id, label => $_->name . " ( ".
    $_->address . "/". $_->prefix . " )" }, $rs->all();
}

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;



