# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::VlanRange;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler::Model::DBIC';
with 'Manoc::FormRenderTable';

has '+name' => ( default => 'form-vlanrange' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
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

has_field 'start' => ( type => 'Integer', required => 1 );
has_field 'end'   => ( type => 'Integer', required => 1 );
has_field 'description' => ( type => 'TextArea' );
has_field 'submit'      => ( type => 'Submit', value => 'Submit' );
has_field 'discard'     => ( type => 'Submit', value => 'Discard' );

1;
