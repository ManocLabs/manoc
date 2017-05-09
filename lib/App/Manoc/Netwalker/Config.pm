package App::Manoc::Netwalker::Config;
#ABSTRACT: Configuration for Manoc Netwalker

use Moose;

##VERSION

use namespace::autoclean;

use Moose::Util::TypeConstraints;
use App::Manoc::Utils::Datetime qw(str2seconds);
use Cwd;

subtype 'TimeInterval', as 'Int',
    where { $_ > 0 },
    message { "The number you provided, $_, was not a positive number" };

coerce 'TimeInterval', from 'Str', via { str2seconds($_) };

=attr manoc_config_dir

used to construct default paths

=cut

has manoc_config_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { getcwd() },
);

=attr n_procs

number of concurrent processes for workers

=cut

has n_procs => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

=attr default_vlan

The default vlan ID to use when fetching ARP and mac address tables.

=cut

=attr default_vlan

=cut

has default_vlan => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

=attr iface_filter

=cut

has iface_filter => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

=attr ignore_portchannel

=cut

has ignore_portchannel => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

=attr mat_force_vlan

=cut

has mat_force_vlan => (
    is      => 'rw',
    isa     => 'Maybe[Int]',
    default => undef,
);

=attr force_full_update

=cut

has force_full_update => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=attr snmp_version

=cut

has snmp_version => (
    is      => 'rw',
    isa     => 'Str',
    default => '2',
);

=attr snmp_community
=cut

has snmp_community => (
    is      => 'rw',
    isa     => 'Str',
    default => 'public',
);

=attr control_port

=cut

has control_port => (
    is      => 'rw',
    isa     => 'Str',
    default => '8001',
);

=attr remote_control

=cut

has remote_control => (
    is      => 'rw',
    isa     => 'Str',
    default => '127.0.0.1',
);

=attr refresh_interval
=cut

has refresh_interval => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '10m',
);

=attr full_update_interval

=cut

has full_update_interval => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '1h'
);

=attr config_update_interval

=cut

has config_update_interval => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '1d',
);

=attr min_backoff_time

=cut

has min_backoff_time => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '5m',
);

=attr max_backoff_time

=cut

has max_backoff_time => (
    is      => 'rw',
    isa     => 'TimeInterval',
    coerce  => 1,
    default => '30m',
);

=attr default_ssh_key

Default to id_dsa, id_ecdsa, id_ed25519 or id_rsa file on manoc config
dir.

=cut

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
