# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ManifoldRole::FetchConfig;
use Moose::Role;

has 'configuration' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_configuration',
);
requires '_build_configuration';


no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
