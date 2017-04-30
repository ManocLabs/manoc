package App::Manoc::Form::VirtualInfr;
use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::Base';
with
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::Horizontal';

has '+item_class'  => ( default => 'VirtualInfr' );
has '+name'        => ( default => 'form-virtualinfr' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    type  => 'Text',
    size  => 32,
    label => 'Name',
);

has_field 'description' => (
    type  => 'Text',
    size  => 64,
    label => 'Description',
);

has_field 'notes' => ( type => 'TextArea' );

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
