package Manoc::Form::DHCPSharedSubnet;

use HTML::FormHandler::Moose;

use namespace::autoclean;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';

use HTML::FormHandler::Types ('IPAddress');

has '+name'        => ( default => 'form-dhcpsharedsubnet' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'DHCPSharedSubnet' );

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

has_field 'dhcp_subnet' => ( 
    type => 'Multiple', 
    label => 'DHCP Subnet', 
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



# sub options_dhcp_subnet {
#     my $self = shift;

#     return unless $self->schema;
#     my $rs = $self->schema->resultset('DHCPSubnet')->search( { 'dhcp_shared_subnet.id' => undef }, {  join => 'dhcp_subnet' , prefetch => 'dhcp_subnet', order_by => 'address'} );

#     return map +{ value => $_->id, label => $_->name . " ( ".
#     $_->address . "/". $_->prefix . " )" }, $rs->all();
# }

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;



