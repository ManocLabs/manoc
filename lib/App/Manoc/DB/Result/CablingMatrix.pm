package App::Manoc::DB::Result::CablingMatrix;

use strict;
use warnings;

use Carp qw(croak);
##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('cabling_matrix_device');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },

    device1_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

    interface1 => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },

    device2_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

    interface2 => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64
    },

    server_nic_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

);

__PACKAGE__->belongs_to(
    server_nic => 'App::Manoc::DB::Result::HWServerNIC',
    'server_nic_id'
);
__PACKAGE__->belongs_to(
    device1 => 'App::Manoc::DB::Result::Device',
    'device1_id'
);
__PACKAGE__->belongs_to(
    device2 => 'App::Manoc::DB::Result::Device',
    'device2_id'
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints(
    cabling_matrix_dev1_idx => [ 'device1_id', 'interface1' ],
    cabling_matrix_nic_idx  => ['server_nic_id'],
);

sub _validate {
    my $self = shift;
    my %data = $self->get_columns;

    if ( $data{device2_id} ) {
        $data{server_nic_id} and
            croak "device2 and server_nic cannot be set together";
        $data{interface2} or
            croak "device2 is set but interface2 is undef";
    }
    else {
        $data{server_nic_id} or
            croak "cabling requires a second device a server nic";
    }
}

=method insert

=cut

sub insert {
    my ( $self, @args ) = @_;

    $self->_validate;

    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->next::method(@args);

    if ( $self->device2_id ) {
        $self->result_source->resultset->find_or_create(
            {
                device1_id => $self->device2_id,
                interface1 => $self->interface2,
                device2_id => $self->device1_id,
                interface2 => $self->interface1,
            }
        );
    }
    $guard->commit;

    return $self;
}

=method update

=cut

sub update {
    my $self    = shift;
    my $columns = shift;

    $self->set_inflated_columns($columns) if $columns;

    my %changed_col_names = map { $_ => 1 } $self->is_changed();

    foreach (qw(device1_id interface1 device2_id interface2 server_nic)) {
        croak "Column $_ cannot be modified" if $changed_col_names{$_};
    }
    $self->next::method(@_);
}

1;
