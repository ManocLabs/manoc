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

has 'arp_table' => (
    is      => 'ro',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    builder => '_build_arp_table',
);
sub _build_arp_table { }

has name => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_name',
);
sub _build_name { undef }

has model => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_model',
);
sub _build_model { undef }

has vendor => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_vendor',
);
sub _build_vendor { undef }

has serial => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_serial',
);
sub _build_serial { undef }

has os => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_os',
);
sub _build_os { undef }

has os_ver => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_os_ver',
);
sub _build_os_ver { undef }


has 'boottime' => (
    is      => 'ro',
    isa     => 'Maybe[Int]',
    lazy    => 1,
    builder => '_build_boottime',
);
sub _build_boottime { undef }


has 'configuration' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_configuration',
);
sub _build_configuration {}


has 'ifstatus_table' => (
    is      => 'ro',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    builder => '_build_ifstatus_table',
);
sub _build_ifstatus_table { }

has 'mat' => (
    is      => 'ro',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    builder => '_build_mat',
);
sub _build_mat { }

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
sub _build_vtp_database {}

no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
