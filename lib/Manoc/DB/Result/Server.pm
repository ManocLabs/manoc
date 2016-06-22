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
    name => {
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
    hwasset_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    ram_memory => {
        data_type   => 'int',
        is_nullable => 0,
    },
    n_procs => {
        data_type     => 'int',
        is_nullable   => 0,
        default_value => 1
    },
    n_cores_procs => {
        data_type     => 'int',
        is_nullable   => 0,
        default_value => 1
    },
    proc_freq => {
        data_type   => 'real',
        is_nullable => 0,
    },
    storage1_size => {
        data_type     => 'real',
        is_nullable   => 0,
        default_value => 0
    },
    storage2_size => {
        data_type     => 'real',
        is_nullable   => 0,
        default_value => 0
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },

    template => {
        data_type     => 'int',
        size          => '1',
        is_nullable   => '1',
        default_value => '0',
    },

);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/address/] );
__PACKAGE__->resultset_class('Manoc::DB::ResultSet::Server');

__PACKAGE__->belongs_to(
    hwasset => 'Manoc::DB::Result::HWAsset',
    'hwasset_id',
    {
        proxy          => [qw/vendor model serial inventory/],
        cascade_update => 1,
        join_type => 'left',
    }
);

__PACKAGE__->belongs_to(
    on_virtinfr => 'Manoc::DB::Result::VirtualInfr',
    'on_virtinfr_id',
    {
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

__PACKAGE__->belongs_to(
    on_hypervisor => 'Manoc::DB::Result::Server',
    'on_hypervisor_id',
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


sub cores {
    my ($self) = @_;
    return $self->n_procs * $self->n_cores_procs;
}

1;
