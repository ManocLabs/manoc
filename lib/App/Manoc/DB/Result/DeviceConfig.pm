package App::Manoc::DB::Result::DeviceConfig;
#ABSTRACT: A model object to store device configuration.

=head1 DESCRIPTION

DeviceConfig stores device configuration as text for backup and mantains previous
configurations in order to implement configuration diff.

=cut

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('device_config');
__PACKAGE__->add_columns(
    'device_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'config' => {
        data_type   => 'text',
        is_nullable => 0
    },
    'prev_config' => {
        data_type   => 'text',
        is_nullable => 1,
    },
    'config_date' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11
    },
    'prev_config_date' => {
        data_type   => 'int',
        size        => 11,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key("device_id");

__PACKAGE__->belongs_to(
    device => 'App::Manoc::DB::Result::Device',
    'device_id',
);

1;
