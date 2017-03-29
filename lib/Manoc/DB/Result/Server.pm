# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Server;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

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
    serverhw => 'Manoc::DB::Result::ServerHW',
    'serverhw_id',
    {
        cascade_update => 1,
        join_type      => 'left',
    }
);

__PACKAGE__->belongs_to(
    vm => 'Manoc::DB::Result::VirtualMachine',
    'vm_id',
    {
        cascade_update => 1,
        join_type      => 'left',
    }
);

__PACKAGE__->belongs_to(
    virtinfr => 'Manoc::DB::Result::VirtualInfr',
    'virtinfr_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->has_many(
    virtual_machines => 'Manoc::DB::Result::VirtualMachine',
    { 'foreign.hypervisor_id' => 'self.id' },
);

__PACKAGE__->has_many(
    nics => 'Manoc::DB::Result::ServerNIC',
    { 'foreign.server_id' => 'self.id' },
    { cascade_delete => 1 }
);


__PACKAGE__->has_many(
    addresses => 'Manoc::DB::Result::ServerAddr',
    { 'foreign.server_id' => 'self.id' },
    { cascade_delete => 1 }
);

__PACKAGE__->might_have(
    netwalker_info => 'Manoc::DB::Result::ServerNWInfo',
    { 'foreign.server_id' => 'self.id' },
    {
        cascade_delete => 1,
        cascade_copy   => 1,
    }
);

__PACKAGE__->has_many(
    installed_sw_pkgs => 'Manoc::DB::Result::ServerSWPkg',
    'server_id'
);

__PACKAGE__->many_to_many(
    software_pkgs => 'installed_sw_pkgs',
    'software_pkg'
);

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
    return wantarray() ? $rs->all() : $rs;
}

sub num_cpus {
    my ($self) = @_;
    if ( $self->serverhw ) {
        return $self->serverhw->n_procs * $self->serverhw->n_cores_procs;
    }
    if ( $self->vm ) {
        return $self->vm->vcpus;
    }
    return undef;
}

sub ram_memory {
    my ($self) = @_;
    if ( $self->serverhw ) {
        return $self->serverhw->ram_memory;
    }
    if ( $self->vm ) {
        return $self->vm->ram_memory;
    }
}

=head2 decommission([timestamp=>$timestamp, recursive=>[0|1]])

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
        foreach my $vm ( $self->virtual_machines ) {
            $vm->server and $vm->server->decommission($timestamp);
            $vm->decommission();
            $vm->update;
        }
    }
    else {
        foreach my $vm ( $self->virtual_machines ) {
            $vm->hypervisor(undef);
            $vm->update;
        }
    }
    $self->update();

    $guard->commit;
}

=head2 restore

=cut

sub restore {
    my $self = shift;

    return unless $self->decommissioned;

    $self->decommissioned(0);
    $self->decommission_ts(undef);
}

=head2 label

=cut

sub label { shift->hostname }

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
