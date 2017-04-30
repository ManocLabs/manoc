# Copyright 2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Form::TraitFor::IPAddr;
use HTML::FormHandler::Moose::Role;

use App::Manoc::IPAddress::IPv4;

=head1 NAME

App::Manoc::Form::TraitFor::RackOptions - Role for populating rack selections

=head1 METHDOS

=head2 get_rack_options

Return an array suitable for populating a Rack select menu

=cut

sub inflate_ipv4 {
    my ( $self, $value ) = @_;
    return App::Manoc::IPAddress::IPv4->new($value)->padded;
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
