# Copyright 2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::HWAsset;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

use Manoc::DB::Result::HWAsset;
use Carp;

sub unused_devices {
    my ( $self ) = @_;

    my $used_asset_ids = $self->result_source->schema->resultset('Device')
        ->search({
            decommissioned     => 0,
            hwasset_id => { -is_not => undef }
        })
        ->get_column('hwasset_id');

    my $assets = $self->search(
        {
            type => Manoc::DB::Result::HWAsset::TYPE_DEVICE,
            location => { '!=' => Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED },
            id =>  {
                -not_in => $used_asset_ids->as_query,
            }
        },
    );

    return $assets;
}


1;
