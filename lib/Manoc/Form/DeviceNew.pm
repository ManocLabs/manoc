# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::DeviceNew;

use strict;
use warnings;
use HTML::FormHandler::Moose;
use Manoc::Utils qw(check_addr);

extends 'HTML::FormHandler::Model::DBIC';
with 'HTML::FormHandler::Render::Table';

has_field 'rack' => (
    type         => 'Select',
    label        => 'Rack name',
    empty_select => '---Choose a Rack---',
);

has_field 'id' => (
    type     => 'Text',
    required => 1,
    label    => 'Ip Address',
    apply    => [
        'Str',
        {
            check   => sub { check_addr( $_[0] ) },
            message => 'Invalid Ip Address'
        },
    ]
);

has_field 'name' => (
    type  => 'Text',
    label => 'Name *',
    apply => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'model' => (
    type  => 'Text',
    label => 'Model *',
    apply => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Model Name'
        },
    ]
);

has_field 'submit'  => ( type => 'Submit', value => 'Submit' );
has_field 'discard' => ( type => 'Submit', value => 'Discard' );

sub options_rack {
    my $self = shift;
    return unless $self->schema;

    my $racks = $self->schema->resultset('Rack')->search(
        {},
        {
            order_by => 'me.name',
            join     => 'building',
            prefetch => 'building'
        }
    );
    my @selections;
    while ( my $rack = $racks->next ) {
        my $label = "Rack " . $rack->name . " (" . $rack->building->name . ")";
        push @selections, { value => $rack->id, label => $label };
    }
    return @selections;
}

1;
