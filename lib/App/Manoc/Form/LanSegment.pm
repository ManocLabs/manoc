package App::Manoc::Form::LanSegment;
#ABSTRACT: Manoc Form for editing lan segment.

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';
with
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::Horizontal';

use namespace::autoclean;

has '+item_class'  => ( default => 'LanSegment' );
has '+name'        => ( default => 'form-lansegment' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    type     => 'Text',
    required => 1,
);

has_field 'notes' => ( type => 'TextArea' );

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
