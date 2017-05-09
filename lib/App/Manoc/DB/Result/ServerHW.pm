package App::Manoc::DB::Result::ServerHW;
##BSTRACT: A model object representing a server hardware asset

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use App::Manoc::DB::Result::HWAsset;

__PACKAGE__->table('serverhw');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    hwasset_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    ram_memory => {
        data_type   => 'int',
        is_nullable => 0,
    },
    cpu_model => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32,
    },
    n_procs => {
        data_type   => 'int',
        is_nullable => 1,
    },
    n_cores_proc => {
        data_type   => 'int',
        is_nullable => 1,
    },
    proc_freq => {
        data_type   => 'int',
        is_nullable => 1,
    },
    storage1_size => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 0
    },
    storage2_size => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 0
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/hwasset_id/] );

my @HWASSET_PROXY_ATTRS = qw(
    location
    vendor model serial inventory
    warehouse_id building_id rack_id rack_level room
);
my @HWASSET_PROXY_METHODS = qw(
    building rack warehouse
    is_decommissioned is_in_warehouse is_in_rack
    move_to_rack move_to_room move_to_warehouse
    decommission restore
    display_location
);

__PACKAGE__->has_one(
    hwasset => 'App::Manoc::DB::Result::HWAsset',
    'id',
    {
        proxy => [ @HWASSET_PROXY_ATTRS, @HWASSET_PROXY_METHODS ],
    }
);

__PACKAGE__->might_have(
    server => 'App::Manoc::DB::Result::Server',
    'serverhw_id',
    {
        cascade_update => 0,
        cascade_delete => 1,
    }
);

__PACKAGE__->has_many(
    nics => 'App::Manoc::DB::Result::ServerNIC',
    { 'foreign.serverhw_id' => 'self.id' },
    { cascade_delete        => 1 }
);

=for Pod::Coverage new

=cut

sub new {
    my ( $self, @args ) = @_;
    my $attrs = shift @args;

    my $new_attrs = {
        'hwasset',
        {
            type      => App::Manoc::DB::Result::HWAsset->TYPE_SERVER,
            location  => App::Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE,
            model     => $attrs->{model},
            vendor    => $attrs->{vendor},
            inventory => $attrs->{inventory},
        }
    };

    $new_attrs->{hwasset}->{type} = App::Manoc::DB::Result::HWAsset->TYPE_SERVER;
    my %proxied_attrs = map { $_ => 1 } @HWASSET_PROXY_ATTRS;
    foreach my $k ( keys %$attrs ) {
        if ( $proxied_attrs{$k} ) {
            $new_attrs->{hwasset}->{$k} = $attrs->{$k};
        }
        else {
            $new_attrs->{$k} = $attrs->{$k};
        }
    }

    return $self->next::method( $new_attrs, @args );
}

=for Pod::Coverage insert

=cut

sub insert {
    my ( $self, @args ) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    # pre-create hwasset if needed
    # so that hwasset_id is not null
    my $hwasset = $self->hwasset;
    if ( !$hwasset->in_storage ) {
        $hwasset->insert;
        $self->hwasset_id( $hwasset->id );
    }

    $self->next::method(@args);
    $guard->commit;
    return $self;
}

=method cores

Return the total number of cores for this machine

=cut

sub cores {
    my ($self) = @_;
    return $self->n_procs * $self->n_cores_procs;
}

=method label

Return a string describing the object

=cut

sub label {
    my $self = shift;

    return $self->inventory . " (" . $self->vendor . " - " . $self->model . ")",;
}

=method in_use

Return true if there is an associated server

=cut

sub in_use { defined( shift->server ); }

1;
