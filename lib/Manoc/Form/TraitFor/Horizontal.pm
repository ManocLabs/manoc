# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::TraitFor::Horizontal;
use HTML::FormHandler::Moose::Role;

=head1 NAME

Manoc::Form::TraitFor::Horizontal - Role for Manoc horizontal forms

=head1 DESCRIPTION

Include this role to create a Bootstrap 3 horizontal forms, using col-sm-2 for labels.

=head1 METHDOS

=head2 build_form_element_class

Set form class to form-horizontal

=cut

sub build_form_element_class { ['form-horizontal'] }

=head2 build_form_tags

Set layout_classes with element_wrapper_class to 'col-sm-10' and
label_class to 'col-sm-2'

=cut

sub build_form_tags {
    {
        'layout_classes' => {
            element_wrapper_class => [ 'col-sm-10' ],
            label_class           => [ 'col-sm-2'  ],
        }
    }
}

=head1 SEE ALSO

L<Manoc::Form::TraitFor::Theme>
L<HTML::FormHandler::Widget::Theme::Bootstrap3>

=head1 AUTHOR

Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no HTML::FormHandler::Moose::Role;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
