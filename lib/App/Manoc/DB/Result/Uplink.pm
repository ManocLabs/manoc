package App::Manoc::DB::Result::Uplink;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('uplinks');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    device_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    interface => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
);

__PACKAGE__->belongs_to( device => 'App::Manoc::DB::Result::Device', 'device_id' );
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( uplink_dev_if_idx => [ 'device_id', 'interface' ] );

__PACKAGE__->might_have(
    cabling => 'App::Manoc::DB::Result::CablingMatrix',
    { 'foreign.hwserver_nic_id' => 'self.id' },
    {
        cascade_copy   => 0,
        cascade_delete => 1,
        cascade_update => 0,
    }
);

sub insert {
    my ( $self, @args ) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    if ( !defined( $self->name ) ) {
        my $rs = $self->result_source->resultset;
        my $count = $rs->search( { serverhw_id => $self->serverhw_id } )->count();
        $self->name("nic$count");
    }

    my $r = $self->next::method(@args);

    $guard->commit;

    return $r;
}

1;
