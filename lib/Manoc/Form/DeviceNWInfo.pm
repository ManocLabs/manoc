# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::DeviceNWInfo;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';

use Manoc::Manifold;

has '+name'        => ( default => 'form-devicenwinfo' );
has '+html_prefix' => ( default => 1 );

has 'device' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has_field 'manifold' => (
    type     => 'Select',
    label    => 'Fetch info with',
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
    label => 'Native VLAN for MAT info',
);

has_field 'get_dot11' => (
    type  => 'Checkbox',
    label => 'Get Dot11 informations'
);

has_field 'get_vtp' => (
    type           => 'Checkbox',
    checkbox_value => 1,
    label          => 'Download VTP DB',
);

#Credentials, don't use username/password to avoid autofilling

has_field 'nw_username' => (
    type     => 'Text',
    label    => 'Username',
    accessor => 'username',
);

has_field 'nw_password' => (
    type      => 'Text',
    label     => 'First level Password',
    accessor  => 'password',
    widget    => 'Password',
    writeonly => 1,
);

has_field 'password2' => (
    type      => 'Text',
    label     => 'Second level Password',
    widget    => 'Password',
    writeonly => 1,
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
    label => 'SNMP Community String'
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
    Manoc::Manifold->load_namespace;
    my @manifolds = Manoc::Manifold->manifolds;
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

    # do not overwrite  passwords when are not edited
    foreach my $k (qw/password password2/) {
        exists $values->{password} or next;

        defined( $values->{password} ) or
            delete $values->{password};
    }

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
