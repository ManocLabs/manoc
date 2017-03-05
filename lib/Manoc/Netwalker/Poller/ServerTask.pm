# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::Poller::ServerTask;

use Moose;
use Try::Tiny;

with 'Manoc::Logger::Role';
use Manoc::Netwalker::Poller::TaskReport;
use Manoc::Manifold;

use Manoc::IPAddress::IPv4;

has 'server_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

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

has 'server_entry' => (
    is      => 'ro',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    builder => '_build_server_entry',
);

has 'nwinfo' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => '_build_nwinfo',
);

has 'credentials' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_credentials',
);

has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { time },
);

# the source for information
has 'source' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_source',
);

# the source for server configuration backup
has 'config_source' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_config_source',
);

has 'task_report' => (
    is       => 'ro',
    required => 0,
    builder  => '_build_task_report',
);

#----------------------------------------------------------------------#
#                                                                      #
#              A t t r i b u t e s   B u i l d e r                     #
#                                                                      #
#----------------------------------------------------------------------#

sub _build_credentials {
    my $self = shift;

    my $credentials = $self->nwinfo->get_credentials_hash;
    $credentials->{snmp_community} ||= $self->config->snmp_community;
    $credentials->{snmp_version}   ||= $self->config->snmp_version;

    return $credentials;
}

sub _build_server_entry {
    my $self = shift;
    my $id   = $self->server_id;

    return $self->schema->resultset('Server')->find( $id );
}

sub _build_nwinfo {
    my $self = shift;

    return $self->server_entry->netwalker_info;
}

sub _create_manifold {
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

sub _build_source {
    my $self = shift;

    my $entry  = $self->server_entry;
    my $nwinfo = $self->nwinfo;

    my $host = $entry->address->unpadded;

    my $manifold_name = $nwinfo->manifold;
    $self->log->debug("Using Manifold $manifold_name");

    my %params = (
        host         => $host,
        credentials  => $self->credentials,
    );

    my $source = $self->_create_manifold( $manifold_name, %params );

    if ( !$source ) {
        my $error = "Cannot create source with manifold $manifold_name";
        $self->log->error($error);
        $self->task_report->add_error($error);
        return undef;
    }

    # auto connect
    if ( !$source->connect() ) {
        my $error = "Cannot connect to $host";
        $self->log->error($error);
        $self->task_report->add_error($error);
        return undef;
    }
    return $source;
}

sub _build_task_report {
    my $self = shift;

    $self->server_entry or return undef;
    my $server_address = $self->server_entry->address->address;
    return Manoc::Netwalker::Poller::TaskReport->new( host => $server_address );
}

sub _build_uplinks {
    my $self = shift;

    my $entry      = $self->server_entry;
    my $source     = $self->source;
    my $server_set = $self->server_set;

    my %uplinks;

    # get uplink from CDP
    my $neighbors = $source->neighbors;

    # filter CDP links
    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {

            # only links to a switch
            next unless $s->{type}->{'Switch'};
            # only links to a kwnown server
            next unless $server_set->{ $s->{addr} };

            $uplinks{$p} = 1;
        }
    }

    # get uplinks from DB and merge them
    foreach ( $entry->uplinks->all ) {
        $uplinks{ $_->interface } = 1;
    }

    return \%uplinks;
}

#----------------------------------------------------------------------#
#                                                                      #
#                       D a t a   u p d a t e                          #
#                                                                      #
#----------------------------------------------------------------------#

sub update {
    my $self = shift;

    # check if there is a server object in the DB
    my $entry = $self->server_entry;
    unless ($entry) {
        $self->log->error( "Cannot find server id ", $self->server_id );
        return undef;
    }

    # load netwalker info from DB
    my $nwinfo = $self->nwinfo;
    unless ($nwinfo) {
        $self->log->error( "No netwalker info for server", $entry->hostname );
        return undef;
    }

    # try to connect and update nwinfo accordingly
    $self->log->info( "Connecting to server ", $entry->hostname, " ", $entry->address );
    if ( !$self->source ) {
        # TODO update nwinfo with connection messages
        $self->nwinfo->offline(1);
        return undef;
    }
    $nwinfo->last_visited( $self->timestamp );
    $nwinfo->offline(0);

    $self->update_server_info;

    $nwinfo->get_packages and
        $self->update_packages;

    $nwinfo->update();
    return 1;
}

#----------------------------------------------------------------------#

sub update_server_info {
    my $self = shift;

    my $source    = $self->source;
    my $server_entry = $self->server_entry;
    my $nw_entry  = $self->nwinfo;

    my $name = $source->name;
    $nw_entry->name($name);
    if ( defined($name) && $name ne $server_entry->hostname ) {
        if ( $server_entry->hostname ) {
            my $msg = "Name mismatch " . $server_entry->hostname . " $name";
            $self->log->warn($msg);
        }
        else {
            $server_entry->hostname($name);
            $server_entry->update;
        }
    }

    $nw_entry->model( $source->model );
    $nw_entry->os( $source->os );
    $nw_entry->os_ver( $source->os_ver );
    $nw_entry->vendor( $source->vendor );
    $nw_entry->serial( $source->serial );

    if ( $source->does('Manoc::ManifoldRole::Host') ) {
        $self->log->debug("Source implements host");

        $nw_entry->kernel( $source->kernel );
        $nw_entry->kernel_ver( $source->kernel_ver );

        $nw_entry->cpu_model( $source->cpu_model );
        $nw_entry->n_procs( $source->cpu_count );

    }

    $nw_entry->boottime( $source->boottime || 0 );

    $nw_entry->update;
}

#----------------------------------------------------------------------#

sub update_packages {
    my $self = shift;

    my $source = $self->source;
    return unless $source->does('Manoc::ManifoldRole::Host');

    my $schema  = $self->schema;
    my $server  = $self->server_entry;

    my $pkgs    = $source->installed_sw;

    $server->installed_sw_pkgs->delete;
    foreach my $p (@$pkgs) {
        my ($name, $version) = @$p;

        my $pkg = $schema->resultset('SoftwarePkg')->find_or_create({name => $name});
        $server->update_or_create_related(
            installed_sw_pkgs => { software_pkg => $pkg, version => $version }
        );
    }
}


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
