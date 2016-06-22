# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::VirtualInfr;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('virtual_infr');

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
    platform => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    version => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },

);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/address/] );

__PACKAGE__->has_many(
    servers => 'Manoc::DB::Result::Server',
    { 'foreign.on_virtinfr_id' => 'self.id' },
);

__PACKAGE__->has_many(
    hypervisors => 'Manoc::DB::Result::Server',
    { 'foreign.hosted_virtinfr_id' => 'self.id' },
);

sub _inflate_address {
    return Manoc::IpAddress::Ipv4->new( { padded => $_[0] } ) if defined( $_[0] );
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

1;
