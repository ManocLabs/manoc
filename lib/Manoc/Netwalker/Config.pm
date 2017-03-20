# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Config;
use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints;
use Manoc::Utils::Datetime qw(str2seconds);
use Cwd;

subtype 'TimeInterval', as 'Int',
    where { $_ > 0 },
    message { "The number you provided, $_, was not a positive number" };

coerce 'TimeInterval', from 'Str', via { str2seconds($_) };

# use to construct default paths
has manoc_config_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { getcwd() },
);

has n_procs => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

has default_vlan => (
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

has control_port => (
    is      => 'rw',
    isa     => 'Str',
    default => '8001',
);

has remote_control => (
    is      => 'rw',
    isa     => 'Str',
    default => '127.0.0.1',
);

has refresh_interval => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '10m',
);

has full_update_interval => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '1h'
);

has config_update_interval => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '1d',
);

has min_backoff_time => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '5m',
);

has max_backoff_time => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '30m',
);

has 'default_ssh_key' => (
    is      => 'rw',
    isa     => 'Str',
    builder => '_build_default_ssh_key',
);

sub _build_default_ssh_key {
    my $self = shift;

    my $basedir = $self->manoc_config_dir;
    foreach (qw( id_dsa id_ecdsa id_ed25519 id_rsa )) {
        my $file = File::Spec->catfile( $basedir, $_ );
        -f $file and return $file;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
