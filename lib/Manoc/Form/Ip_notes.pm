# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Ip_notes;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler::Model::DBIC';
with 'Manoc::FormRenderTable';

has '+name' => ( default => 'form-ipnotes' );
has '+html_prefix' => ( default => 1 );

has_field 'ipaddr' => (
    type     => 'Text',
    label    => 'Ip Address',
    disabled => 1,
);

has_field 'notes' => ( type => 'TextArea', );

has_field 'submit'  => ( type => 'Submit', value => 'Submit' );
has_field 'discard' => ( type => 'Submit', value => 'Discard' );

1;
