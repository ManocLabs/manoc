package App::Manoc::Form::Types::VlanID;

use Moose::Util::TypeConstraints;

##VERSION

subtype 'VlanID' => as 'Int' => where { $_ >= 1 && $_ <= 4094 } =>
    message { "VLAN ID must be in 1-4094" };

no Moose::Util::TypeConstraints;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
