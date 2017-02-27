# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ManifoldRole::Base;
use Moose::Role;

requires 'connect';

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'credentials' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'extra_params' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} }
);

has name => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_name',
);
requires '_build_name';

has model => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_model',
);
requires '_build_model';

has vendor => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_vendor',
);
requires '_build_vendor';

has serial => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_serial',
);
requires '_build_serial';

has os => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_os',
);
requires '_build_os';

has os_ver => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_os_ver',
);
requires '_build_os_ver';

has 'boottime' => (
    is      => 'ro',
    isa     => 'Maybe[Int]',
    lazy    => 1,
    builder => '_build_boottime',
);
requires '_build_boottime'; { undef }

no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
