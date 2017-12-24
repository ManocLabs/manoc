package App::Manoc::Form::Base;

use HTML::FormHandler::Moose;

##VERSION

extends 'HTML::FormHandler';
with
    'App::Manoc::Form::TraitFor::Theme',
    'App::Manoc::Form::TraitFor::CSRF';

# with 'HTML::FormHandlerX::Form::JQueryValidator';

#required for CSRF
has '+ctx'      => ( required => 1, );
has '+is_html5' => ( default  => 1 );

# has_field validation_json => ( type => 'Hidden',  element_attr => { disabled => 'disabled' } );
# sub default_validation_json { shift->as_escaped_json }

sub html_attributes {
    my ( $self, $field, $type, $attr ) = @_;
    if ( $type eq 'label' && $field->{required} ) {
        # highlight required fields
        push @{ $attr->{class} }, 'required-label';
    }
    return $attr;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
