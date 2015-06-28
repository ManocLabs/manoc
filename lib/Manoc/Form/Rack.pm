# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Rack;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';

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
    label        => 'Building',
);

has_field 'floor' => (
    type => 'Integer',
    required => 1,
    label  => 'Floor',
);
has_field 'notes' => (
    type => 'TextArea',
    label => 'Notes',
);

has_field 'save' => (
    type => 'Submit',
    widget => 'ButtonTag',
    element_attr => { class => ['btn', 'btn-primary'] },
    widget_wrapper => 'None',
    value => "Save"
);

sub options_building {
    my $self = shift;
    return unless $self->schema;
    my @buildings = $self->schema->resultset('Building')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@buildings) {
        my $label = $b->name . " (" . $b->description . ")";
        my $option = {
	    label => $label,
	    value => $b->id
	};
        push @selections, $option;
    }
    return @selections;
}

1;
