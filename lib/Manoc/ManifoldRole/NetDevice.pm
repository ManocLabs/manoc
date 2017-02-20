# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ManifoldRole::NetDevice;
use Moose::Role;

has 'neighbors' => (
    is      => 'ro',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    builder => '_build_neighbors',
);
sub _build_neighbors { }

has 'vtp_domain' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_vtp_domain',
);
sub _build_vtp_domain { }

has vtp_database => (
    is      => 'ro',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    builder => '_build_vtp_database'
);
sub _build_vtp_database { }

no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
