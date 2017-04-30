package App::Manoc::Form::VlanRange;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';
with
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::Horizontal';

use App::Manoc::Form::Types::VlanID;

has '+name'        => ( default => 'form-vlanrange' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    label    => 'Name',
    type     => 'Text',
    required => 1,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ],
);

has_field 'start' => (
    label    => 'From VLAN',
    type     => 'Integer',
    apply    => ['VlanID'],
    required => 1,
);

has_field 'end' => (
    label    => 'To VLAN',
    type     => 'Integer',
    apply    => ['VlanID'],
    required => 1,
);

has_field 'description' => (
    label => 'Description',
    type  => 'TextArea',
);

sub validate {
    my $self = shift;

    $self->field('end')->value < $self->field('start')->value and
        $self->field('end')->add_error('Not a valid range');
}

override validate_model => sub {
    my $self = shift;

    # some handy shortcuts
    my $start = $self->field('start')->value;
    my $end   = $self->field('end')->value;
    my $item  = $self->item;

    # check for overlapping ranges (excluding self!)
    my $rs = $self->source->resultset;
    my $overlap = $rs->get_overlap_ranges( $start, $end );
    $overlap = $overlap->search( id => { '<>' => $self->item->id } )
        if $item->in_storage;
    $overlap->count() > 0 and
        $self->add_form_error('Overlaps with existing range');

    # check for vlans outside boundaries
    if ( $item->in_storage ) {
        $item->vlans->search( { id => { '<' => $start } } )->count() > 0 and
            $self->field('start')
            ->add_error(
            'There are associated vlans which will be below the lower end of the range');
        $item->vlans->search( { id => { '>' => $end } } )->count() > 0 and
            $self->field('end')
            ->add_error(
            'There are associated vlans which will be above the upper end of the range');
    }
};

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
