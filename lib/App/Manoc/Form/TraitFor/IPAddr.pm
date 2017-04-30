package App::Manoc::Form::TraitFor::IPAddr;

#ABSTRACT: Role for populating rack selections

use HTML::FormHandler::Moose::Role;

##VERSION

use App::Manoc::IPAddress::IPv4;

=head1 METHDOS

=head2 get_rack_options

Return an array suitable for populating a Rack select menu

=cut

sub inflate_ipv4 {
    my ( $self, $value ) = @_;
    return App::Manoc::IPAddress::IPv4->new($value)->padded;
}

no HTML::FormHandler::Moose::Role;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
