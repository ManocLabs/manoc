# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Form::VlanRange::Split;

use HTML::FormHandler::Moose;
extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-vlanrangesplit' );
has '+html_prefix' => ( default => 1 );

has_field 'new_name' => (
    label    => 'New range name',
    type     => 'Text',
    required => 1,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'direction' => (
    type    => 'Select',
    widget  => 'RadioGroup',
    options => [
        { value => 'UP',   label => 'New range above' },
        { value => 'DOWN', label => 'New range below' },
    ],
);

has_field 'split_point' => (
    label    => 'Split at VLAN ID',
    type     => 'Integer',
    apply    => ['VlanID'],
    required => 1
);

sub validate {
    my $self = shift;

    my $item_start  = $self->item->start;
    my $item_end    = $self->item->end;
    my $split_point = $self->field('split_point')->value;
    if ( $split_point <= $item_start || $split_point >= $item_end ) {
        $self->field('split_point')
            ->add_error("Split point should be withing the range $item_start-$item_end");
    }
}

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    return $self->item->split_new_range( $values->{new_name}, $values->{split_point},
        $values->{direction}, );
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
