# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Form::DeviceNWInfo;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::SaveButton';

use constant EMPTY_PASSWORD => '######';

use App::Manoc::Manifold;

has '+name'        => ( default => 'form-devicenwinfo' );
has '+html_prefix' => ( default => 1 );

has 'device' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has_field 'manifold' => (
    type     => 'Select',
    label    => 'Collect info with',
    required => 1,
);

has_field 'config_manifold' => (
    type  => 'Select',
    label => 'Fetch config with',
);

#Retrieved Info

has_field 'get_config' => (
    type  => 'Checkbox',
    label => 'Get configuration',
);

has_field 'get_arp' => (
    type           => 'Checkbox',
    checkbox_value => 1,
    label          => 'Get ARP table',
);

has_field 'arp_vlan' => (
    type  => 'Select',
    label => 'ARP info on VLAN',
);

has_field 'get_mat' => (
    type  => 'Checkbox',
    label => 'Get MAT'
);

has_field 'mat_native_vlan' => (
    type  => 'Select',
    label => 'Native VLAN for MAT information',
);

has_field 'get_dot11' => (
    type  => 'Checkbox',
    label => 'Get Dot11 information'
);

has_field 'get_vtp' => (
    type           => 'Checkbox',
    checkbox_value => 1,
    label          => 'Download VTP database',
);

#Credentials, don't use username/password to avoid autofilling

has_field 'nw_username' => (
    type     => 'Text',
    label    => 'Username',
    accessor => 'username',
);

has_field 'nw_password' => (
    type      => 'Text',
    label     => 'First level password',
    widget    => 'Password',
    writeonly => 1,
);

sub default_nw_password {
    my $self = shift;
    my $item = $self->item;

    return unless $item;

    $item->password and return EMPTY_PASSWORD;
    return '';
}
has_field 'nw_password2' => (
    type      => 'Text',
    label     => 'Sudo password',
    widget    => 'Password',
    writeonly => 1,
);

sub default_nw_password2 {
    my $self = shift;
    my $item = $self->item;

    return unless $item;

    $item->password2 and return EMPTY_PASSWORD;
    return '';
}

has_field 'use_ssh_key' => (
    type  => 'Checkbox',
    label => 'Use private key for SSH',
);

has_field 'key_path' => (
    type  => 'Text',
    label => 'Path to SSH key',
);

has_field 'snmp_version' => (
    type    => 'Select',
    label   => 'SNMP version',
    options => [
        { value => 0, label => 'Use Default', selected => '1' },
        { value => 1, label => 1 },
        { value => 2, label => '2c' },
        { value => 3, label => 3 }
    ],
);

has_field 'snmp_community' => (
    type  => 'Text',
    label => 'SNMP community string'
);

has_field 'snmp_user' => (
    type  => 'Text',
    label => 'SNMP user'
);

has_field 'snmp_password' => (
    type   => 'Text',
    label  => 'SNMP password',
    widget => 'Password',
);

sub options_manifold {
    return shift->_manifold_list;
}

sub options_config_manifold {
    return shift->_manifold_list;
}

sub _manifold_list {
    App::Manoc::Manifold->load_namespace;
    my @manifolds = App::Manoc::Manifold->manifolds;
    return map +{ value => $_, label => $_ }, sort(@manifolds);
}

sub options_mat_native_vlan {
    shift->_get_vlan_list;
}

sub options_arp_vlan {
    shift->_get_vlan_list;
}

has _vlan_list => (
    is  => 'rw',
    isa => 'ArrayRef',
);

sub _get_vlan_list {
    my $self = shift;
    return unless $self->schema;

    return @{ $self->_vlan_list } if $self->_vlan_list;

    my $rs = $self->schema->resultset('Vlan')->search( {}, { order_by => 'id' } );
    my @list = map +{ value => $_->id, label => $_->name . " (" . $_->id . ")" }, $rs->all();

    $self->_vlan_list( \@list );
    return @list;
}

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    # do not overwrite passwords when are not edited
    $values->{nw_password} ne EMPTY_PASSWORD and
        $values->{password} = $values->{nw_password};
    $values->{nw_password2} ne EMPTY_PASSWORD and
        $values->{password2} = $values->{nw_password2};

    $values->{device} = $self->{device};
    $self->_set_value($values);

    super();
};

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
