package App::Manoc::DB::Result::ServerHWNIC;
#ABSTRACT: A model object for server additional network interfaces

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use constant {
    NW_STATUS_UNKNOWN   => undef,    # never checked by nw
    NW_STATUS_FOUND     => 'F',      # nw ran and confirmed this nic
    NW_STATUS_NOT_FOUND => 'N',      # nw ran and didn't find this nic
    NW_STATUS_CREATED   => 'C',      # nw ran and created this nic
};

__PACKAGE__->table('serverhw_nic');
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

    nic_type_id => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32
    },

    macaddr => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 17
    },

    nw_status => {
        data_type   => 'char',
        size        => 1,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( [ 'serverhw_id', 'name' ], ['macaddr'] );

__PACKAGE__->belongs_to(
    serverhw => 'App::Manoc::DB::Result::ServerHW',
    { 'foreign.id' => 'self.serverhw_id' }
);

__PACKAGE__->belongs_to(
    nic_type => 'App::Manoc::DB::Result::NICType',
    { 'foreign.id' => 'self.nic_type_id' }
);

__PACKAGE__->might_have(
    cabling => 'App::Manoc::DB::Result::CablingMatrix',
    'interface1_id'
);

=method insert

Override to allow automatic name creation

=cut

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

    return $self;
}

=method label

=cut

sub label { shift->name }

1;
