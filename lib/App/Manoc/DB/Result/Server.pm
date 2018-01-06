package App::Manoc::DB::Result::Server;
#ABSTRACT: A model object representing a server

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('servers');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    hostname => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 128,
    },
    address => {
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
    },
    os => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    os_ver => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    is_hypervisor => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },
    # the server is an hypervisor in a virtual infrastructure
    virtinfr_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    # used if this is a physical server
    serverhw_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    # used if this is a virtual server
    vm_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    decommissioned => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },

    decommission_ts => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },

    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },

);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/address/] );

__PACKAGE__->belongs_to(
    serverhw => 'App::Manoc::DB::Result::ServerHW',
    'serverhw_id',
    {
        cascade_update => 1,
        join_type      => 'left',
    }
);

__PACKAGE__->belongs_to(
    vm => 'App::Manoc::DB::Result::VirtualMachine',
    'vm_id',
    {
        cascade_update => 1,
        join_type      => 'left',
    }
);

__PACKAGE__->belongs_to(
    virtinfr => 'App::Manoc::DB::Result::VirtualInfr',
    'virtinfr_id',
    {
        join_type => 'LEFT',
    }
);

__PACKAGE__->has_many(
    virtual_machines => 'App::Manoc::DB::Result::VirtualMachine',
    { 'foreign.hypervisor_id' => 'self.id' },
);

__PACKAGE__->has_many(
    addresses => 'App::Manoc::DB::Result::ServerAddr',
    { 'foreign.server_id' => 'self.id' },
    { cascade_delete      => 1 }
);

__PACKAGE__->might_have(
    netwalker_info => 'App::Manoc::DB::Result::ServerNWInfo',
    { 'foreign.server_id' => 'self.id' },
    {
        cascade_delete => 1,
        cascade_copy   => 1,
    }
);

__PACKAGE__->has_many(
    installed_sw_pkgs => 'App::Manoc::DB::Result::ServerSWPkg',
    'server_id'
);

__PACKAGE__->many_to_many(
    software_pkgs => 'installed_sw_pkgs',
    'software_pkg'
);

=method virtual_servers

If this server is an hypervisor return associacte virtual servers

=cut

sub virtual_servers {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Server');
    $rs = $rs->search(
        {
            'vm.hypervisor_id' => $self->id,
        },
        {
            join => 'vm',
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method num_cpus

Return the number of cpus for the associated physical or virtual machine

=cut

sub num_cpus {
    my ($self) = @_;
    if ( $self->serverhw ) {
        return $self->serverhw->cores;
    }
    if ( $self->vm ) {
        return $self->vm->vcpus;
    }
    return;
}

=method ram_memory

Return the ram memory for associated virtual of physical machine

=cut

sub ram_memory {
    my ($self) = @_;
    if ( $self->serverhw ) {
        return $self->serverhw->ram_memory;
    }
    if ( $self->vm ) {
        return $self->vm->ram_memory;
    }
}

=method decommission([timestamp=>$timestamp, recursive=>[0|1]])

Set decommissioned to true, update timestamp.
When recursive option is set decommission hosted VMs and servers.

=cut

sub decommission {
    my $self      = shift;
    my %args      = @_;
    my $timestamp = $args{timestamp} // time();

    $self->decommissioned and return 1;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->decommissioned(1);
    $self->decommission_ts($timestamp);
    $self->serverhw_id(undef);
    $self->vm_id(undef);

    if ( $args{recursive} ) {
        foreach my $vm ( $self->virtual_machines->all ) {
            $vm->server and $vm->server->decommission($timestamp);
            $vm->decommission();
            $vm->update;
        }
    }
    else {
        foreach my $vm ( $self->virtual_machines->all ) {
            $vm->hypervisor(undef);
            $vm->update;
        }
    }
    $self->update();

    $guard->commit;
}

=method restore

Restore decommissioned object

=cut

sub restore {
    my $self = shift;

    return unless $self->decommissioned;

    $self->decommissioned(0);
    $self->decommission_ts(undef);
}

=method label

Return a string describing the object

=cut

sub label { shift->hostname }

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
