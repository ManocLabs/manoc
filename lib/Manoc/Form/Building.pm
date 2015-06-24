# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Building;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::Base::Actions';

has '+name' => ( default => 'form-building' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    label    => 'Name',
    type     => 'Text',
    required => 1,
    apply    => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);
has_field 'description' => (
    label => 'Description',
    type  => 'TextArea',
    required => 1
);
has_field 'notes' => ( type => 'TextArea' );



1;

