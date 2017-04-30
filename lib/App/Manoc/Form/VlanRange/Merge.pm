package App::Manoc::Form::VlanRange::Merge;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::SaveButton';

has_field 'range' => (
    type         => 'Select',
    empty_select => '--- Choose a VLAN range ---',
    required     => 1,
    label        => 'Merge with',
);

sub options_range {
    my $self = shift;
    return unless $self->schema;

    my @ranges = $self->item->get_mergeable_ranges( { order_by => 'start' } );

    return map +{
        label => $_->name,
        value => $_->id,
    }, @ranges;
}

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    my $other_range = $self->source->resultset->find( $values->{range} );
    return $self->item->merge_with_range($other_range);
};

__PACKAGE__->meta->make_immutable;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
