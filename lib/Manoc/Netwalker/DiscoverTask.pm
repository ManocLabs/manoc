# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::DiscoverTask;

use Moose;
with 'Manoc::Logger::Role';

use Try::Tiny;
use Class::Load qw(load_class);

use Manoc::Manifold::SNMP::Simple;
use Manoc::IPAddress::IPv4;

use Net::Ping;
use Socket;

has 'schema' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1
);

has 'config' => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Config',
    required => 1
);

has 'session_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'address' => (
    is       => 'ro',
    isa      => 'Manoc::IPAddress::IPv4',
    required => 1
);

has 'session' => (
    is      => 'ro',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    builder => '_build_session',
);

has 'credentials' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_credentials',
);

has 'ping_handler' => (
    is      => 'ro',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    builder => '_build_ping_handler'
);

sub _build_credentials {
    my $self = shift;

    my $credentials = {
        snmp_community => $self->session->snmp_community
    };
    $credentials->{snmp_community} ||= $self->config->snmp_community;
    $credentials->{snmp_version}   = $self->config->snmp_version;

    return $credentials;
}

sub _build_session {
    my $self      = shift;

    return $self->schema->resultset('DiscoverSession')->find( $self->session_id );
}

sub _build_ping_handler {
    my $self = shift;
    return Net::Ping->new();
}

sub create_manifold {
    my $self          = shift;
    my $manifold_name = shift;
    my %params        = @_;

    my $manifold;
    try {
        $manifold = Manoc::Manifold->new_manifold( $manifold_name, %params );
    }
    catch {
        my $error = "Internal error while creating manifold $manifold_name: $_";
        $self->log->debug($error);
        return undef;
    };

    $manifold or $self->log->debug("Manifold constructor returned undef");
    return $manifold;
}

sub scan {
    my ($self) = @_;

    my $address = $self->address->unpadded;
    $self->log->debug("ping $address");

    if ( ! $self->ping_handler->ping($address) ) {
        $self->log->debug("$address is not alive, skipping");
        return;
    }

    my $discovered_host = $self->session->find_or_create_related('discovered_hosts', {address => $address});

    try {
        my $name = gethostbyaddr($address, AF_INET);
        $self->log->debug("querying dns for $address");
        $discovered_host->hostname($name);
    };

    if ($self->session->use_snmp) {
        $self->log->debug("snmp scan $address");
        try {
            my $m = $self->create_manifold('SNMP::Simple',
                                           credentials => $self->credentials,
                                           host        => $address
                                       );
            $m->connect;
            $discovered_host->vendor($m->vendor);
            $discovered_host->os($m->os);
            $discovered_host->os($m->os_ver);

            $discovered_host->hostname($m->name);
        } catch {
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
