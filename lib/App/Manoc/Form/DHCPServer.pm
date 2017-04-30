package App::Manoc::Form::DHCPServer;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-dhcpserver' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'DHCPServer' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Name',
);

has_field 'max_lease_time' => (
    type  => 'Integer',
    label => 'Default maximum lease time',
);
has_field 'default_lease_time' => (
    type  => 'Integer',
    label => 'Default lease time',
);
has_field 'ntp_server' => (
    type  => 'Text',
    label => 'Default NTP Server',
);
has_field 'domain_nameserver' => (
    type  => 'Text',
    label => 'Default Domain Nameserver',
);
has_field 'domain_name' => (
    type  => 'Text',
    label => 'Default Domain Name',
);

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
