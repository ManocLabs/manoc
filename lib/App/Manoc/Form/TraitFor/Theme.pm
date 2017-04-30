package App::Manoc::Form::TraitFor::Theme;

use Moose::Role;

##VERSION

with 'HTML::FormHandler::Widget::Theme::Bootstrap3';

# widget wrapper must be set before the fields are built in BUILD

sub build_do_form_wrapper { 1 }

sub build_form_tags {
    { wrapper_tag => 'div', };
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
