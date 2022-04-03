package App::Manoc::Form::VlanRange;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';
with
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::Horizontal';

use App::Manoc::Form::Types::VlanID;

has '+name' => ( default => 'form-vlanrange' );

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

has_field 'lan_segment' => (
    type         => 'Select',
    empty_select => '--- Choose a LAN Segment ---',
    required     => 1,
    label        => 'LAN Segment',
);

has_field 'start' => (
    label    => 'From id',
    type     => 'Integer',
    apply    => ['VlanID'],
    required => 1,
);

has_field 'end' => (
    label    => 'To id ',
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
    my $start          = $self->field('start')->value;
    my $end            = $self->field('end')->value;
    my $lan_segment_id = $self->field('lan_segment')->value;

    my $item = $self->item;

    # check for overlapping ranges (excluding self!)
    my $rs      = $self->source->resultset;
    my $overlap = $rs->get_overlap_ranges( $lan_segment_id, $start, $end );
    $overlap = $overlap->search( id => { '<>' => $self->item->id } )
        if $item->in_storage;
    $overlap->count() > 0 and
        $self->add_form_error('Overlaps with existing range');
};

sub options_lan_segment {
    my $self = shift;
    return unless $self->schema;
    my @lan_segments =
        $self->schema->resultset('LanSegment')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $s (@lan_segments) {
        my $option = {
            label => $s->name,
            value => $s->id
        };
        push @selections, $option;
    }
    return @selections;
}

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
