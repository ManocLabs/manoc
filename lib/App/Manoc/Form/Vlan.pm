package App::Manoc::Form::Vlan;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

use App::Manoc::Form::Types::VlanID;

has '+name' => ( default => 'form-vlan' );

has '+item_class' => ( default => 'Vlan' );

has_field 'lan_segment' => (
    type         => 'Select',
    empty_select => '--- Choose a LAN Segment ---',
    required     => 1,
    label        => 'LAN Segment',
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

sub options_lan_segment {
    my $self = shift;
    return unless $self->schema;
    my @lansegments =
        $self->schema->resultset('LanSegment')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@lansegments) {
        my $option = {
            label => $b->name,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

__PACKAGE__->meta->make_immutable;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
