# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::IPBlock;

use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';

use namespace::autoclean;

has '+item_class' => ( default => 'IPBlock' );

has_field 'description' => ( type => 'TextArea', label => 'description', );
has_field 'to_addr' => ( type => 'Text', size => 15, required => 1, label => 'to_addr', );
has_field 'from_addr' => ( type => 'Text', size => 15, required => 1, label => 'from_addr', );
has_field 'name' => ( type => 'TextArea', required => 1, label => 'name', );
has_field 'submit' => ( widget => 'Submit', label =>'Submit');

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
