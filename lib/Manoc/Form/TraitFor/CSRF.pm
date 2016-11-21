# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::TraitFor::CSRF;
use HTML::FormHandler::Moose::Role;

=head1 NAME

Manoc::Form::TraitFor::CSRF - Role for Manoc forms CSRF

=head1 DESCRIPTION

Include this role to include a CSRF hidden form.

=cut

has_field 'csrf_token' => (
    type     => 'Hidden',
    noupdate => 1,
    do_wrapper   => 0,
);

sub default_csrf_token {
    my $self = shift;

    return $self->ctx->get_token;
}

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
