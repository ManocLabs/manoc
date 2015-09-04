# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Device;

use strict;
use warnings;
use Manoc::Utils::IPAddress qw(check_addr);
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';

has '+name' => ( default => 'form-device' );
has '+html_prefix' => ( default => 1 );

has_field 'mng_address' => (
    type     => 'Text',
    label    => 'IP Address',
    required => 1,
    apply    => [
	'Str',
	{
	    check   => sub { check_addr( $_[0] ) },
	    message => 'Invalid Ip Address'
	},
    ]
);

has_field 'name' => (
    type  => 'Text',
    required => 1,
    apply => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'model' => (
    type  => 'Text',
    apply => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Model Name'
        },
    ]
);

#Location
has_field 'rack' => (
    type         => 'Select',
    label        => 'Rack name',
    empty_select => '---Choose a Rack---',
    required     => 1,
);

has_field 'level' => (
    label    => 'Level',
    type     => 'Text',
    required => 1,
);

#Retrieved Info

has_field 'backup_enable' => (
    type     => 'Checkbox',
    accessor => 'backup_enabled',
);

has_field 'get_arp' => (
    type           => 'Checkbox',
    checkbox_value => 1,
    label          => 'Get ARP'
);

has_field 'vlan_arpinfo' => (
    type  => 'Select',
    label => 'ARP info on VLAN',
);

has_field 'get_mat' => (
    type  => 'Checkbox',
    label => 'Get MAT'
);

has_field 'mat_native_vlan' => (
    type  => 'Select',
    label => 'Native VLAN for MAT info',
);

has_field 'get_dot11' => (
    type  => 'Checkbox',
    label => 'Get Dot11'
);

#Credentials
has_field 'telnet_pwd' => ( type => 'Text', label => 'Telnet Password' );
has_field 'enable_pwd' => ( type => 'Text', label => 'Enable Password' );

has_field 'snmp_ver' => (
    type    => 'Select',
    label   => 'SNMP version',
    options => [
        { value => 0, label => 'Use Default', selected => '1' },
        { value => 1, label => 1 },
        { value => 2, label => '2c' },
        { value => 3, label => 3 }
    ],
);

has_field 'snmp_com'      => ( type => 'Text', label => 'SNMP Community String' );
has_field 'snmp_user'     => ( type => 'Text', label => 'SNMP user' );
has_field 'snmp_password' => ( type => 'Text', label => 'SNMP password' );

has_field 'notes' => ( type => 'TextArea' );

has_field 'mng_url_format' => (
    type         => 'Select',
    label        => 'Management URL',
    empty_select => '---Choose a Format---'
);

has_field 'save' => (
    type => 'Submit',
    widget => 'ButtonTag',
    element_attr => { class => ['btn', 'btn-primary'] },
    widget_wrapper => 'None',
    value => "Save"
);

sub options_rack {
    my $self = shift;
    return unless $self->schema;

    my $racks = $self->schema->resultset('Rack')->search(
        {},
        {
            join     => 'building',
            prefetch => 'building',
            order_by => 'me.name'
        }
    );

    return map +{
        value => $_->id,
        label => "Rack " . $_->name . " (" . $_->building->name . ")"
        },
        $racks->all();
}

sub options_mng_url_format {
    my $self = shift;

    return unless $self->schema;
    my $rs = $self->schema->resultset('MngUrlFormat')->search( {}, { order_by => 'name' } );

    return map +{ value => $_->id, label => $_->name }, $rs->all();
}

sub options_mat_native_vlan {
    my $self = shift;
    return $self->_do_options_vlan()
}

sub options_vlan_arpinfo {
    my $self = shift;
    return $self->_do_options_vlan()
}

sub _do_options_vlan {
    my $self = shift;

    return unless $self->schema;
    my $rs = $self->schema->resultset('Vlan')->search( {}, { order_by => 'id' } );

    return map +{ value => $_->id, label => $_->name . " (" . $_->id . ")" }, $rs->all();
}


=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
