# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::ServerNWInfo;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';

use Manoc::Manifold;

has '+name'        => ( default => 'form-servernwinfo' );
has '+html_prefix' => ( default => 1 );

has 'server' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has_field 'manifold' => (
    type     => 'Select',
    label    => 'Collect info with',
    required => 1,
);

#Retrieved Info

has_field 'get_packages' => (
    type  => 'Checkbox',
    label => 'Get installed software',
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
    accessor  => 'password',
    widget    => 'Password',
    writeonly => 1,
);

has_field 'password2' => (
    type      => 'Text',
    label     => 'Second level password',
    widget    => 'Password',
    writeonly => 1,
);

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
    Manoc::Manifold->load_namespace;

    my @manifolds = Manoc::Manifold->manifolds;
    return map +{ value => $_, label => $_ }, sort(@manifolds);
}

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    # do not overwrite passwords when are not edited
    foreach my $k (qw/password password2/) {
        exists $values->{$k} or next;

        defined( $values->{$k} ) or
            delete $values->{$k};
    }

    $values->{server} = $self->{server};
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
