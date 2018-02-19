package App::Manoc::Form::ServerNWInfo;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
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
    $values->{nw_become_password} ne EMPTY_PASSWORD and
        $values->{become_password} = $values->{nw_become_password};

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
