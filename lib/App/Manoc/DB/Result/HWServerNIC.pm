package App::Manoc::DB::Result::HWServerNIC;
#ABSTRACT: A model object for server additional network interfaces

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('hw_server_nic');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },

    serverhw_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

    name => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32
    },

    macaddr => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 17
    },

);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [ 'serverhw_id', 'name' ], ['macaddr'] );

__PACKAGE__->belongs_to(
    serverhw => 'App::Manoc::DB::Result::ServerHW',
    { 'foreign.id' => 'self.serverhw_id' }
);

sub insert {
    my ( $self, @args ) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    if ( !defined( $self->name ) ) {
        my $rs = $self->result_source->resultset;
        my $count = $rs->search( { serverhw_id => $self->serverhw_id } )->count();
        $self->name("nic$count");
    }

    $self->next::method(@args);

    $guard->commit;
}

1;
