package App::Manoc::Form::Vlan;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

use App::Manoc::Form::Types::VlanID;

has '+name'        => ( default => 'form-vlan' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'Vlan' );

has 'vlan_range' => (
    is       => 'ro',
    required => 1,
);

has_field 'vid' => (
    label    => 'VLAN ID',
    type     => 'Integer',
    apply    => ['VlanID'],
    required => 1,
);

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Vlan name',
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'description' => (
    label => 'Description',
    type  => 'TextArea'
);

override validate_model => sub {
    my $self = shift;

    my $vlan_id   = $self->field('vid')->value;
    my $range     = $self->vlan_range;
    my $vlan_from = $range->start;
    my $vlan_to   = $range->end;

    my $error = 0;

    if ( $vlan_id < $vlan_from || $vlan_id > $vlan_to ) {
        $self->field('vid')->add_error("VLAN ID must be within range $vlan_from-$vlan_to");
        $error++;
    }

    super() or $error++;

    return $error ? undef : 1;
};

before 'update_model' => sub {
    my $self   = shift;
    my $values = $self->value;
    my $item   = $self->item;

    $item->vlan_range( $self->vlan_range );
};

__PACKAGE__->meta->make_immutable;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
