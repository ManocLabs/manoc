package App::Manoc::Form::ServerNWInfo;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::SaveButton';

use App::Manoc::Manifold;

use constant EMPTY_PASSWORD => '######';

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

has_field 'get_vms' => (
    type  => 'Checkbox',
    label => 'Get virtual machines',
);

has_field 'update_vm' => (
    type  => 'Checkbox',
    label => 'Update Virtual Machine info',
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

has_field 'use_sudo' => (
    type  => 'Checkbox',
    label => 'Use sudo for privileged commands',
);

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
    App::Manoc::Manifold->load_namespace;

    my @manifolds = App::Manoc::Manifold->manifolds;
    return map +{ value => $_, label => $_ }, sort(@manifolds);
}

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    # do not overwrite passwords when are not edited
    $values->{nw_password} ne EMPTY_PASSWORD and
        $values->{password} = $values->{nw_password};
    $values->{nw_password2} ne EMPTY_PASSWORD and
        $values->{password2} = $values->{nw_password2};

    $values->{server} = $self->{server};
    $self->_set_value($values);

    super();
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
