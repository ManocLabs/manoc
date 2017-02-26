# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ManifoldRole::Host;
use Moose::Role;

has 'installed_sw' => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    lazy    => 1,
    builder => '_build_installed_sw',
);
requires '_build_installed_sw';

has 'cpu_model' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_cpu_model',
);
requires '_build_cpu_model';


has 'cpu_count' => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_cpu_count',
);
requires '_build_cpu_count';


no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
