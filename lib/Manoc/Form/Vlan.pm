# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Vlan;

use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::Base::SaveButton';


has '+name' => ( default => 'form-vlan' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Vlan name',
    apply    => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'description' => ( type => 'TextArea' );

__PACKAGE__->meta->make_immutable;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

