package App::Manoc::DB::Result::WorkstationHW;
#ABSTRACT: Workstation Hardware

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use App::Manoc::DB::Result::HWAsset;

__PACKAGE__->table('workstationhw');

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

    ethernet_macaddr => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 17
    },

    wireless_macaddr => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 17
    },

    display => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 255,
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
    warehouse_id building_id room
);
my @HWASSET_PROXY_METHODS = qw(
    building rack warehouse
    is_decommissioned is_in_warehouse
    move_to_room move_to_warehouse
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
    workstation => 'App::Manoc::DB::Result::Workstation',
    'workstationhw_id',
    {
        cascade_delete => 1,
    }
);

=for Pod::Coverage new

=cut

# override new in order to initialize the required hwasset
sub new {
    my ( $self, @args ) = @_;
    my $attrs = shift @args;

    my $new_attrs = {
        'hwasset' => {
            type      => App::Manoc::DB::Result::HWAsset->TYPE_WORKSTATION,
            location  => App::Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE,
            model     => $attrs->{model},
            vendor    => $attrs->{vendor},
            inventory => $attrs->{inventory},
        }
    };

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

Return the number of cores

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

True if used by a Workstation

=cut

sub in_use { defined( shift->workstation ); }

1;
