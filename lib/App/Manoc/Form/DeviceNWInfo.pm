package App::Manoc::Form::DeviceNWInfo;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

use App::Manoc::Manifold;

has '+name' => ( default => 'form-devicenwinfo' );

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

has_field 'credentials' => (
    type  => 'Select',
    label => 'Credentials',
);

sub options_credentials {
    my $self = shift;
    return unless $self->schema;
    my @credentials =
        $self->schema->resultset('Credentials')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@credentials) {
        my $option = {
            label => $b->name,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

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
