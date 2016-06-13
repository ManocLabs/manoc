package Manoc::Form::DHCPSubnet;

use HTML::FormHandler::Moose;

use namespace::autoclean;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';

use HTML::FormHandler::Types ('IPAddress');

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

has_field 'network' => ( 
    type => 'Select', 
    label => 'Network', 
);

has_field 'range' => ( 
    type => 'Select', 
    label => 'IP Pool', 
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



