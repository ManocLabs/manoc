package App::Manoc::Form::Types;
#ABSTRACT: Manoc form types
use strict;
use warnings;

##VERSION

use MooseX::Types -declare => [ 'MacAddress', ];

use MooseX::Types::Moose ( 'Str', 'Num', 'Int' );

use App::Manoc::Utils qw(normalize_mac_addr);

=head1 DESCRIPTION

Inspired by HTML::FormHandler::Types

=head1 Type Constraints

These types check the value and issue an error message.

=cut

=head2 MacAddress

A valid mac address in aa-bb-cc-dd-ee format. Other format like
aaaa-bbbb-cccc are automatically converted.


=cut

subtype MacAddress, as Str, where {
    /^[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}$/
}, message { "Not a valid mac address in aa:bb:cc:dd:ff format" };

coerce MacAddress, from Str, via {
    return normalize_mac_addr($_);
};

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
