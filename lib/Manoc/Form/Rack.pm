# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Rack;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler::Model::DBIC';
with 'Manoc::FormRenderTable';

has '+name' => ( default => 'form-rack' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Rack name',
    apply    => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '---Choose a Building---',
    required     => 1,
);

has_field 'floor' => ( type => 'Integer', required => 1 );
has_field 'notes' => ( type => 'TextArea' );

has 'default_building_id' => (
    is       => 'ro',
    required => 0
);

has_field 'submit'  => ( type => 'Submit', value => 'Submit' );
has_field 'discard' => ( type => 'Submit', value => 'Discard' );

sub options_building {
    my $self = shift;
    return unless $self->schema;
    my $buildings = $self->schema->resultset('Building')->search( {}, { order_by => 'id' } );
    my @selections;
    while ( my $build = $buildings->next ) {
        my $label = $build->name . " (" . $build->description . ")";
        my $option = { label => $label, value => $build->id };
        $self->default_building_id and
            $self->default_building_id == $build->id and
            $option->{selected} = 1;
        push @selections, $option;
    }
    return @selections;
}

1;
