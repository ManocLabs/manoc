# Copyright 2017- by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::ManifoldRole::Hypervisor;
use Moose::Role;

# expected map:
#  - uuid
#  - name
#  - state (optional)
#  - cpus (optional)
#  - memsize (optional)
has 'virtual_machines' => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    lazy    => 1,
    builder => '_build_virtual_machines',
);
requires '_build_virtual_machines';

no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
