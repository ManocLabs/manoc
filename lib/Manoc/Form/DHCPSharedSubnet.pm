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
     noupdate => 1,
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

around 'update_model' => sub {
    my $orig = shift;
    my $self = shift;
    my $item = $self->item;
    my $subnet_list =  $self->field('dhcp_subnet')->value;

    $self->schema->txn_do( sub {
	$self->$orig(@_);
	
	foreach my $sub_id (@{$subnet_list}){
	    my $rs = $self->schema->resultset('DHCPSubnet')
		->search( { 'id' => $sub_id  },)->single; 
	    $rs->dhcp_shared_subnet($item)->update;
	}         
   });
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;



