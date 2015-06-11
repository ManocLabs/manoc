# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::IfNotes;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler::Model::DBIC';
with 'Manoc::FormRenderTable';

has '+name' => ( default => 'form-ifnotes' );
has '+html_prefix' => ( default => 1 );

has 'device' => (
    is  => 'ro',
    isa => 'Int',
);

has 'interface' => (
    is  => 'ro',
    isa => 'Str',
);

has_field 'notes' => (
    type => 'TextArea',
    required => 1,
    label => 'Notes',
);

has_field 'submit'  => ( type => 'Submit', value => 'Submit' );
has_field 'discard' => ( type => 'Submit', value => 'Discard' );

override 'update_model' => sub {
    my $self   = shift;

    $self->values->{device} = $self->{device};
    $self->values->{interface} = $self->{interface};

    super();
};
1;
