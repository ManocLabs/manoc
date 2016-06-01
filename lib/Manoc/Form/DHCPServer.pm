package Manoc::Form::DHCPServer;

use HTML::FormHandler::Moose;

use namespace::autoclean;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-dhcpserver' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'DHCPServer' );

has_field 'name' => ( 
    type => 'Text', 
    required => 1, 
    label => 'Name',
);

has_field 'max_lease_time' => ( 
    type => 'Integer', 
    label => 'Default maximum lease time', 
);
has_field 'default_lease_time' => ( 
    type => 'Integer', 
    label => 'Default lease time', 
);
has_field 'ntp_server' => ( 
    type => 'Text', 
    label => 'Default NTP Server', 
);
has_field 'domain_nameserver' => ( 
    type => 'Text', 
    label => 'Default Domain Nameserver', 
);
has_field 'domain_name' => ( 
    type => 'Text', 
    label => 'Default Domain Name', 
);



#has_field 'dhcp_network' => ( type => '+Manoc::Form::DHCPNetworkField', );



__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;



#{
#    package Manoc::Form::DHCPNetworkField;
#    use HTML::FormHandler::Moose;
#    extends 'HTML::FormHandler::Field::Compound';
#    use namespace::autoclean;
#
#    has_field 'range_to' => ( type => 'Text', size => 15, required => 1, label => 'range_to', );
#    has_field 'range_from' => ( type => 'Text', size => 15, required => 1, label => 'range_from', );
#    has_field 'max_lease_time' => ( type => 'Integer', label => 'max_lease_time', );
#    has_field 'default_lease_time' => ( type => 'Integer', label => 'default_lease_time', );
#    has_field 'ntp_server' => ( type => 'TextArea', label => 'ntp_server', );
#    has_field 'domain_nameserver' => ( type => 'TextArea', label => 'domain_nameserver', );
#    has_field 'domain_name' => ( type => 'TextArea', label => 'domain_name', );
#    has_field 'name' => ( type => 'TextArea', required => 1, label => 'name', );
#    has_field 'network' => ( type => 'Select', label => 'network', );
#    has_field 'dhcp_server' => ( type => 'Select', label => 'dhcp_server', );
#    
#    __PACKAGE__->meta->make_immutable;
#    no HTML::FormHandler::Moose;
#}
#
#
