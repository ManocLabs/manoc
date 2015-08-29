# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Ip;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';

has 'ipaddr' => (
    isa => 'Str',
    is  => 'ro',
    required => 1,
);

has_field 'description' => ( type  => 'TextArea' );

has_field 'assigned_to' => ( type  => 'Text',
			     label => 'Assigned to' );

has_field 'phone'       => ( type => 'Text' );

has_field 'email'       => ( type => 'Email', );

has_field 'notes'       => ( type => 'TextArea', );

has_field 'save' => (
    type => 'Submit',
    widget => 'ButtonTag',
    element_attr => { class => ['btn', 'btn-primary'] },
    widget_wrapper => 'None',
    value => "Save"
);

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    $values->{ipaddr} = $self->ipaddr;
    $self->_set_value($values);

    super();
};

1;
