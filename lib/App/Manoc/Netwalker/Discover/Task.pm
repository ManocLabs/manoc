package App::Manoc::Netwalker::Discover::Task;
#ABSTRACT: Netwalker discover task

=head1 DESCRIPTION

A class which implements a scan on a single IP address and eventuallu
store its findings in Manoc DB.

=cut

use Moose;

##VERSION

with 'App::Manoc::Logger::Role';

use Try::Tiny;
use Class::Load qw(load_class);

use App::Manoc::Manifold::SNMP::Simple;
use App::Manoc::IPAddress::IPv4;

use Net::Ping;
use Socket;

=attr schema
=cut

has 'schema' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1
);

=attr config
=cut

has 'config' => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);

=attr session_id

Identifier for the current discovery session. Required.

=cut

has 'session_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

=attr session

Current discovery session, identified by session id.

=cut

has 'session' => (
    is      => 'ro',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    builder => '_build_session',
);

=attr address

L<App::Manoc::IPAddress::IPv4> object pointing the target of the scan. Required.

=cut

has 'address' => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    required => 1
);

=attr credentials

Netwalker credentials hash. Defaults to use Netwalker configuration.

=cut

has 'credentials' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_credentials',
);

has '_ping_handler' => (
    is      => 'ro',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    builder => '_build_ping_handler'
);

sub _build_credentials {
    my $self = shift;

    my $credentials = { snmp_community => $self->session->snmp_community };
    $credentials->{snmp_community} ||= $self->config->snmp_community;
    $credentials->{snmp_version} = $self->config->snmp_version;

    return $credentials;
}

sub _build_session {
    my $self = shift;

    return $self->schema->resultset('DiscoverSession')->find( $self->session_id );
}

sub _build_ping_handler {
    my $self = shift;
    return Net::Ping->new();
}

sub _create_manifold {
    my $self          = shift;
    my $manifold_name = shift;
    my %params        = @_;

    my $manifold;
    try {
        $manifold = App::Manoc::Manifold->new_manifold( $manifold_name, %params );
    }
    catch {
        my $error = "Internal error while creating manifold $manifold_name: $_";
        $self->log->debug($error);
        return;
    };

    $manifold or $self->log->debug("Manifold constructor returned undef");
    return $manifold;
}

=method scan

Ping C<$self->address> by using ping and if it's alive try to get information using DNS and SNMP::Simple.

=cut

sub scan {
    my ($self) = @_;

    my $address = $self->address->unpadded;
    $self->log->debug("ping $address");

    if ( !$self->_ping_handler->ping($address) ) {
        $self->log->debug("$address is not alive, skipping");
        return;
    }

    my $discovered_host =
        $self->session->find_or_create_related( 'discovered_hosts', { address => $address } );

    try {
        my $name = gethostbyaddr( $address, AF_INET );
        $self->log->debug("querying dns for $address");
        $discovered_host->hostname($name);
    };

    if ( $self->session->use_snmp ) {
        $self->log->debug("snmp scan $address");
        try {
            my $m = $self->_create_manifold(
                'SNMP::Simple',
                credentials => $self->credentials,
                host        => $address
            );
            $m->connect;
            $discovered_host->vendor( $m->vendor );
            $discovered_host->os( $m->os );
            $discovered_host->os( $m->os_ver );

            $discovered_host->hostname( $m->name );
        }
        catch {
            $self->log->debug("got error $_ while scanning snmp");
        };
    }

    $discovered_host->update();
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
