package Manoc::Form::DHCPNetwork;
use HTML::FormHandler::Moose;

use namespace::autoclean;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';


has '+item_class' => ( default => 'DHCPNetwork' );

    has_field 'name' => ( type => 'TextArea', required => 1, label => 'name', );


    has_field 'range_to' => ( type => 'Text', size => 15, required => 1, label => 'range_to', );
    has_field 'range_from' => ( type => 'Text', size => 15, required => 1, label => 'range_from', );
    has_field 'max_lease_time' => ( type => 'Integer', label => 'max_lease_time', );
    has_field 'default_lease_time' => ( type => 'Integer', label => 'default_lease_time', );
    has_field 'ntp_server' => ( type => 'TextArea', label => 'ntp_server', );
    has_field 'domain_nameserver' => ( type => 'TextArea', label => 'domain_nameserver', );
    has_field 'domain_name' => ( type => 'TextArea', label => 'domain_name', );
    has_field 'network' => ( type => 'Select', label => 'network', );

    has_field 'dhcp_server' => ( type => 'Select', label => 'dhcp_server', );

    __PACKAGE__->meta->make_immutable;
    no HTML::FormHandler::Moose;

#    has_field 'reservations' => ( type => '+Manoc::Form::DHCPReservationField', );
#    has_field 'leases' => ( type => '+Manoc::Form::DHCPLeaseField', );




#{
#    package Manoc::Form::DHCPReservationField;
#    use HTML::FormHandler::Moose;
#    extends 'HTML::FormHandler::Field::Compound';
#    use namespace::autoclean;
#
#    has_field 'hostname' => ( type => 'TextArea', required => 1, label => 'hostname', );
#    has_field 'name' => ( type => 'TextArea', required => 1, label => 'name', );
#    has_field 'ipaddr' => ( type => 'Text', size => 15, required => 1, label => 'ipaddr', );
#    has_field 'macaddr' => ( type => 'Text', size => 17, required => 1, label => 'macaddr', );
#    has_field 'server' => ( type => 'TextArea', required => 1, label => 'server', );
#    has_field 'dhcp_network' => ( type => 'Select', label => 'dhcp_network', );
#    
#    __PACKAGE__->meta->make_immutable;
#    no HTML::FormHandler::Moose;
#}
#
#
#{
#    package Manoc::Form::DHCPLeaseField;
#    use HTML::FormHandler::Moose;
#    extends 'HTML::FormHandler::Field::Compound';
#    use namespace::autoclean;
#
#    has_field 'status' => ( type => 'Text', size => 16, required => 1, label => 'status', );
#    has_field 'end' => ( type => 'Integer', required => 1, label => 'end', );
#    has_field 'start' => ( type => 'Integer', required => 1, label => 'start', );
#    has_field 'hostname' => ( type => 'TextArea', required => 1, label => 'hostname', );
#    has_field 'ipaddr' => ( type => 'Text', size => 15, required => 1, label => 'ipaddr', );
#    has_field 'macaddr' => ( type => 'Text', size => 17, required => 1, label => 'macaddr', );
#    has_field 'server' => ( type => 'TextArea', required => 1, label => 'server', );
#    has_field 'dhcp_network' => ( type => 'Select', label => 'dhcp_network', );
#    
#    __PACKAGE__->meta->make_immutable;
#    no HTML::FormHandler::Moose;
#}
#
#
