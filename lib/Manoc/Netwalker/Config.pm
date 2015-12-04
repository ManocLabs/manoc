# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Config;
use Moose;
use namespace::autoclean;

has n_procs  => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

has default_vlan  => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

has iface_filter => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

has ignore_portchannel => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has mat_force_vlan => (
    is      => 'rw',
    isa     => 'Maybe[Int]',
    default => undef,
);

has force_full_update => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has full_update_interval => (
    is      => 'rw',
    isa     => 'Int',
    default => 60 * 60 * 24,
);

has snmp_version => (
    is      => 'rw',
    isa     => 'Str',
    default => '2',
);


has snmp_community => (
    is      => 'rw',
    isa     => 'Str',
    default => 'public',
);

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
