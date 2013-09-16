# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Ip;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler::Model::DBIC';
with 'Manoc::FormRenderTable';

has_field 'ipaddr' => (
    type     => 'Text',
    label    => 'Ip Address',
    disabled => 1,
);

has_field 'description' => ( type  => 'TextArea' );

has_field 'client'      => ( type  => 'Text', 
			     label => 'Client' );

has_field 'contact'     => ( type  =>  'Text', 
			     label =>  'Client Contact' );

has_field 'phone'       => ( type => 'Text' );

has_field 'email' => ( type => 'Email', );

has_field 'notes' => ( type => 'TextArea', );

has_field 'submit'  => ( type => 'Submit', value => 'Submit' );
has_field 'discard' => ( type => 'Submit', value => 'Discard' );

1;
