package App::Manoc::DB::Result::CablingMatrix;

use strict;
use warnings;

use Carp qw(croak);
##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('cabling_matrix');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },

    interface1_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

    device1_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
        accessor       => '_device1_id',
    },

    interface2_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

    hwserver_nic_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },

);

__PACKAGE__->belongs_to(
    device1 => 'App::Manoc::DB::Result::Device',
    { 'foreign.id' => 'self.device1_id' },
);

__PACKAGE__->belongs_to(
    interface1 => 'App::Manoc::DB::Result::DeviceIface',
    { 'foreign.id' => 'self.interface1_id' },
);

__PACKAGE__->belongs_to(
    interface2 => 'App::Manoc::DB::Result::DeviceIface',
    { 'foreign.id' => 'self.interface2_id' },
    { join_type    => 'LEFT' }
);

__PACKAGE__->belongs_to(
    serverhw_nic => 'App::Manoc::DB::Result::ServerHWNIC',
    { 'foreign.id' => 'self.hwserver_nic_id' },
    { join_type    => 'LEFT' }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints(
    cabling_matrix_iface_idx => ['interface1_id'],
    cabling_matrix_nic_idx   => ['hwserver_nic_id'],
);

=method device2

=cut

sub device2 {
    my $self = shift;
    $self->interface2 or return;
    return $self->interface2->device;
}

=method serverhw

=cut

sub serverhw {
    my $self = shift;
    $self->serverhw_nic or return;
    return $self->serverhw_nic->serverhw;
}

sub _validate {
    my $self = shift;
    my %data = $self->get_columns;

    if ( $data{interface2_id} ) {
        $data{hwserver_nic_id} and
            croak "interface2 and hwserver_nic cannot be set together";
    }
    else {
        $data{hwserver_nic_id} or
            croak "cabling requires a second interface or a server nic";
    }
}

=method insert

=cut

sub insert {
    my ( $self, @args ) = @_;

    $self->_device1_id( $self->interface1->device_id );

    $self->_validate;
    $self->next::method(@args);

    return $self;
}

=method update

=cut

sub update {
    my $self    = shift;
    my $columns = shift;

    $self->set_inflated_columns($columns) if $columns;

    my %changed_col_names = map { $_ => 1 } $self->is_changed();

    foreach (qw(device1_id interface1_id interface2_id hwserver_nic_id)) {
        croak "Column $_ cannot be modified" if $changed_col_names{$_};
    }
    $self->next::method(@_);
}

1;
