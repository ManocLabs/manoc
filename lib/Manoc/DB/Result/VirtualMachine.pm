# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::VirtualMachine;
use Moose;

extends 'DBIx::Class::Core';

__PACKAGE__->table('virtual_machines');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    identifier => {
        data_type   => 'varchar',
        size        => 36,
        is_nullable => 1,
    },
    name => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15,
    },

    # the virtual infrastructure is running the
    virtinfr_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

    # the hypervisor which is hosting this server
    hypervisor_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    ram_memory => {
        data_type   => 'int',
        is_nullable => 1,
    },

    vcpus => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 1
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

__PACKAGE__->belongs_to(
    virtinfr => 'Manoc::DB::Result::VirtualInfr',
    'virtinfr_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->belongs_to(
    hypervisor => 'Manoc::DB::Result::Server',
    'hypervisor_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->might_have(
    server => 'Manoc::DB::Result::Server',
    'vm_id',
);

=head2 label

=cut

sub label {
    my $self = shift;

    my $label = $self->name;
    if ( $self->virtinfr ) {
        $label .= ' - ' . $self->virtinfr->name;
    }
    elsif ( $self->hypervisor ) {
        $label .= ' - ' . $self->hypervisor->hostname;
    }
    return $label;
}

=head2 decommission

Set decommissioned to true, update timestamp and de associate server if
needed.

=cut

sub decommission {
    my $self = shift;
    my $timestamp = shift // time();

    $self->decommissioned and return 1;

    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->decommissioned(1);
    $self->decommission_ts($timestamp);

    if ( $self->server ) {
        $self->server->vm_id(undef);
        $self->server->update();
    }
    $self->hypervisor_id(undef);
    $self->update;

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

=head2 in_use

Return true if vm is used by a server

=cut

sub in_use { defined( shift->server ); }



1;
