package App::Manoc::Form::TraitFor::CSRF;
#ABSTRACT: Role for CSRF support in Manoc forms

use HTML::FormHandler::Moose::Role;

##VERSION

=head1 DESCRIPTION

Include this role to include a CSRF hidden form.

=cut

has_field 'csrf_token' => (
    type       => 'Hidden',
    noupdate   => 1,
    do_wrapper => 0,
);

sub default_csrf_token {
    my $self = shift;

    return $self->ctx->get_token;
}

no HTML::FormHandler::Moose::Role;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
