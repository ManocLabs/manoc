package App::Manoc::DB::Result::IPAddressInfo;
#ABSTRACT: A model object for information on IP addresses

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('ipaddr_info');

__PACKAGE__->add_columns(
    'ipaddr' => {
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
    },
    'description' => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
    },
    'assigned_to' => {
        data_type   => 'varchar',
        size        => 45,
        is_nullable => 1,
    },
    'phone' => {
        data_type   => 'varchar',
        size        => 30,
        is_nullable => 1,
    },
    'email' => {
        data_type   => 'varchar',
        size        => 45,
        is_nullable => 1,
    },
    'notes' => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('ipaddr');

1;
