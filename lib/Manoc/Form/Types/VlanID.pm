# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Types::VlanID;

use Moose::Util::TypeConstraints;

subtype 'VlanID'
    => as 'Int'
    => where { $_ >= 1 && $_ <= 4094 }
    => message { "VLAN ID must be in 1-4094" };


no Moose::Util::TypeConstraints;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
