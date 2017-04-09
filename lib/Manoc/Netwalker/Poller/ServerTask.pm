# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::Poller::ServerTask;

use Moose;
use Try::Tiny;

with
    'Manoc::Netwalker::Poller::BaseTask',
    'Manoc::Logger::Role';

use Manoc::Netwalker::Poller::TaskReport;
use Manoc::Manifold;

use Manoc::IPAddress::IPv4;

has 'server_id' => (
    is       => 'ro',
    isa      => 'Int',
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

sub _build_server_entry {
    my $self = shift;
    my $id   = $self->server_id;

    return $self->schema->resultset('Server')->find($id);
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
        host        => $host,
        credentials => $self->credentials,
        use_sudo    => $nwinfo->use_sudo,
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
        $self->reschedule_on_failure;
        $nwinfo->offline(1);
        $nwinfo->update();
        return undef;
    }

    $self->update_server_info;

    $nwinfo->get_packages and
        $self->update_packages;

    $nwinfo->get_vms and
        $self->fetch_virtual_machines;

    $self->reschedule_on_success;
    $nwinfo->last_visited( $self->timestamp );
    $nwinfo->offline(0);

    $nwinfo->update();
    $self->log->debug( "Server ", $entry->hostname, " ", $entry->address, " updated" );

    return 1;
}

=head2 update_server_info

=cut

sub update_server_info {
    my $self = shift;

    my $source       = $self->source;
    my $server_entry = $self->server_entry;
    my $nw_entry     = $self->nwinfo;

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
        $nw_entry->ram_memory( $source->ram_memory );

        $nw_entry->update_vm and $self->update_vm;
    }

    $nw_entry->boottime( $source->boottime || 0 );

    $nw_entry->update;
}

#----------------------------------------------------------------------#

=head2 update_vm

=cut

sub update_vm {
    my $self = shift;

    my $source       = $self->source;
    my $server_entry = $self->server_entry;
    my $nw_entry     = $self->nwinfo;
    my $vm           = $server_entry->vm;

    my $uuid = $source->uuid;
    return unless defined($uuid);

    # nothing to change
    defined($vm) && defined( $vm->identifier ) &&
        lc($uuid) eq lc( $vm->identifier ) and
        return;

    if ( defined($vm) && !defined( $vm->identifier ) ) {
        $self->log->debug("Setting related vm uuid $uuid");
        $vm->identifier($uuid);
        $vm->update;
    }
    else {
        my @virtual_machines;

        if ( defined($vm) && defined( $vm->hypervisor ) ) {
            $self->log->debug(
                "Searching for vm with $uuid in the same hypervisor or infrastructure");

            # check if there is already an unused vm with the given uuid in the same hypervisor
            # or infrastructure
            my $hypervisor = $vm->hypervisor;
            my $vm_rs      = (
                $hypervisor->virtinfr ? $hypervisor->virtinfr->virtual_machines :
                    $hypervisor->virtual_machines
            );
            @virtual_machines = $vm_rs->unused->search(
                {
                    identifier => { -in => [ lc($uuid), uc($uuid) ] }
                }
            );
        }
        elsif ( !defined( $server_entry->serverhw ) ) {
            $self->log->debug("Searching for vm with $uuid and compatible name");

            my @names;
            my $hostname = $server_entry->hostname;
            push @names, $hostname;
            $hostname =~ /^([^.]+)\./ and push @names, $1;

            @virtual_machines = $self->schema->resultset('VirtualMachine')->unused->search(
                {
                    identifier => { -in => [ lc($uuid), uc($uuid) ] },
                    name       => { -in => \@names }
                }
            );
        }
        if ( @virtual_machines == 1 ) {
            my $new_vm = $virtual_machines[0];
            $self->log->debug("Associating vm $uuid");
            $server_entry->vm($new_vm);
            $server_entry->update;
        }
    }
}

=head2 fetch_virtual_machines

=cut

sub fetch_virtual_machines {
    my $self = shift;

    my $source = $self->source;
    return unless $source->does('Manoc::ManifoldRole::Hypervisor');

    my $server = $self->server_entry;
    return unless $server->is_hypervisor;

    my $server_id = $server->id;
    my $timestamp = $self->timestamp;

    my $vm_rs = (
        $server->virtinfr ? $server->virtinfr->virtual_machines :
            $server->virtual_machines
    );

    my $vm_list = $source->virtual_machines;

    return unless $vm_list;

    foreach my $vm_info (@$vm_list) {
        my $uuid = $vm_info->{uuid};

        my $vm;

        # search for uuid in hypervisor/virtualinfr
        my @vms = $vm_rs->search( { identifier => $uuid } );
        if ( @vms > 1 ) {
            $self->log->warn(
                "More than a vm with the same uuid $uuid. Info will not be updated.");
            next;
        }
        if ( @vms == 1 ) {
            $vm = $vms[0];
        }

        # search for uuid among detached vms
        if (!$vm) {
            $self->log->debug("Searching detached vm with $uuid.");
            my @detached_vms = $self->schema->resultset('VirtualMachine')->search(
                {
                    identifier => $uuid,
                    hypervisor_id => undef,
                    virtinfr_id=>undef
                }
            );
            if ( @detached_vms == 1) {
                $vm = $detached_vms[0];
                $self->log->info("Reclaimed detached vm $uuid.");
                $vm->hypervisor($server);
            }
        }

        # create a new vm
        if (!$vm) {
            $self->log->info("Creating new vm $uuid.");

            $vm = $self->schema->resultset('VirtualMachine')->new_result( {} );
            $vm->identifier($uuid);
            $vm->hypervisor($server);
        }

        # update vm info
        $self->log->debug("Updated vm $uuid.");
        $vm->name( $vm_info->{name} );
        $vm->vcpus( $vm_info->{vcpus} );
        $vm->ram_memory( $vm_info->{memsize} );
        $vm->update_or_insert();

        $self->schema->resultset('HostedVm')->register_tuple(
            hypervisor_id => $server_id,
            vm_id         => $vm->id,
            timestamp     => $timestamp,
        );
    }    # end of virtual machines loop

}

=head2 update_packages

=cut

sub update_packages {
    my $self = shift;

    my $source = $self->source;
    return unless $source->does('Manoc::ManifoldRole::Host');

    my $schema = $self->schema;
    my $server = $self->server_entry;

    my $pkgs = $source->installed_sw;

    $server->installed_sw_pkgs->delete;
    foreach my $p (@$pkgs) {
        my ( $name, $version ) = @$p;

        my $pkg = $schema->resultset('SoftwarePkg')->find_or_create( { name => $name } );
        $server->update_or_create_related(
            installed_sw_pkgs => { software_pkg => $pkg, version => $version } );
    }
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
