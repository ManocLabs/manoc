package App::Manoc::Form::Credentials;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

use constant EMPTY_PASSWORD => '######';

has '+name'        => ( default => 'form-credentials' );
has '+html_prefix' => ( default => 1 );

#Credentials, don't use username/password to avoid autofilling

has_field 'name' => (
    type  => 'Text',
    label => 'Set Name',
);

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

has_field 'nw_become_password' => (
    type      => 'Text',
    label     => 'Sudo password',
    widget    => 'Password',
    writeonly => 1,
);

sub default_nw_become_password {
    my $self = shift;
    my $item = $self->item;

    return unless $item;

    $item->become_password and return EMPTY_PASSWORD;
    return '';
}

has_field 'ssh_key' => (
    type  => 'TextArea',
    label => 'SSH key',
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

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    # do not overwrite passwords when are not edited
    $values->{nw_password} ne EMPTY_PASSWORD and
        $values->{password} = $values->{nw_password};
    $values->{nw_become_password} ne EMPTY_PASSWORD and
        $values->{become_password} = $values->{nw_become_password};

    $values->{device} = $self->{device};
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
