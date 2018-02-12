package App::Manoc::Form::DHCPSharedNetwork;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

use HTML::FormHandler::Types ('IPAddress');

has '+name' => ( default => 'form-dhcpsharednetwork' );

has '+item_class' => ( default => 'DHCPSharedNetwork' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Name',
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'dhcp_server' => ( type => 'Hidden' );

has_field 'max_lease_time' => (
    type  => 'Integer',
    label => 'Maximum Lease Time',
);

has_field 'default_lease_time' => (
    type  => 'Integer',
    label => 'Default Lease Time',
);

has_field 'ntp_server' => (
    type  => 'Text',
    size  => 15,
    apply => [IPAddress],
    label => 'Ntp Server',
);

has_field 'domain_nameserver' => (
    type  => 'Text',
    size  => 15,
    apply => [IPAddress],
    label => 'Domain Nameserver',
);

has_field 'domain_name' => (
    type  => 'Text',
    label => 'Domain Name',
);

before 'update_model' => sub {
    my $self = shift;

    if ( $self->item->in_storage ) {
        delete $self->values->{dhcp_server};
    }
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
