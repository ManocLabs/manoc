# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Server;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

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
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15,
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

    # used if the server is running on a virtual infrastructure
    on_virtinfr_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    # the hypervisor which is hosting this server
    on_hypervisor_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    # the server is an hypervisor in a virtual infrastructure
    hosted_virtinfr_id => {
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

    # used if this is a physical server
    servervm_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/address/] );

__PACKAGE__->belongs_to(
    serverhw => 'Manoc::DB::Result::ServerHW',
    'serverhw_id',
    {
        cascade_update => 1,
        join_type => 'left',
    }
);

__PACKAGE__->belongs_to(
    servervm => 'Manoc::DB::Result::HWAsset',
    'serverhw_id',
    {
        cascade_update => 1,
        join_type => 'left',
    }
);


__PACKAGE__->belongs_to(
    hosted_virtinfr => 'Manoc::DB::Result::VirtualInfr',
    'hosted_virtinfr_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->has_many(
    virtual_machines => 'Manoc::DB::Result::Server',
    { 'foreign.on_hypervisor_id' => 'self.id' },
);

sub _inflate_address {
    return Manoc::IPAddress::IPv4->new( { padded => $_[0] } ) if defined( $_[0] );
}

sub _deflate_address {
    return scalar $_[0]->padded if defined( $_[0] );
}

__PACKAGE__->inflate_column(
    address => {
        inflate => \&_inflate_address,
        deflate => \&_deflate_address,
    }
);


sub num_cpus {
    my ($self) = @_;
    if ($self->serverhw) {
        return $self->serverhw->n_procs * $self->serverhw->n_cores_procs;
    }
    if ($self->servervm) {
        return $self->servervm->vcpus;
    }
    return undef;
}

sub ram_memory {
    my ($self) = @_;
    if ($self->serverhw) {
        return $self->serverhw->ram_memory;
    }
    if ($self->servervm) {
        return $self->servervm->ram_memory;
    }
}

1;
