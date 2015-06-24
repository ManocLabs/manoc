# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Base;
use utf8;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler::Model::DBIC';
with 'Manoc::Form::Base::Theme';

# with 'HTML::FormHandlerX::Form::JQueryValidator';

# has_field validation_json => ( type => 'Hidden',  element_attr => { disabled => 'disabled' } );
# sub default_validation_json { shift->as_escaped_json }

sub html_attributes {
    my ( $self, $field, $type, $attr ) = @_;
    if ($type eq 'label' && $field->{required}) {
        my $label = $field->{label};
        $field->{label} = "$label *" unless $label =~ /\*$/;
    }
    return $attr;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
