# Copyright 2017 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Warehouse;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Horizontal';
with 'Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-warehouse' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Name',
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '---Choose a Building---',
    required     => 0,
    label        => 'Building',
);

has_field 'floor' => (
    type     => 'Integer',
    required => 0,
    label    => 'Floor',
);

has_field 'room' => (
    type     => 'Text',
    size     => 32,
    required => 0
);

has_field 'notes' => (
    type     => 'TextArea',
    label    => 'Notes',
    required => 0,
    row      => 3,
);

has '+dependency' => (
    default => sub {
        [ [ 'floor', 'building' ], ];
    }
);

sub options_building {
    my $self = shift;
    return unless $self->schema;
    my @buildings =
        $self->schema->resultset('Building')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@buildings) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

=head1 AUTHOR

The Manoc Team

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
