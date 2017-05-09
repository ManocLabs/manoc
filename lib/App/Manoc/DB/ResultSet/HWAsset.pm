package App::Manoc::DB::ResultSet::HWAsset;
#ABSTRACT: ResultSet class for HWAsset

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Result::HWAsset;
use Carp;

=method unused_devices

Return a resultset of all device hardware assets which are not in use by a
non-decommissioned device.

=cut

sub unused_devices {
    my ($self) = @_;

    my $used_asset_ids = $self->result_source->schema->resultset('Device')->search(
        {
            'subquery.decommissioned' => 0,
            'subquery.hwasset_id'     => { -is_not => undef }
        },
        {
            alias => 'subquery',
        }
    )->get_column('hwasset_id');

    my $me = $self->current_source_alias;
    my $rs = $self->search(
        {
            "$me.type" => App::Manoc::DB::Result::HWAsset::TYPE_DEVICE,
            "$me.location" =>
                { '!=' => App::Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED },
            "$me.id" => {
                -not_in => $used_asset_ids->as_query,
            }
        },
    );
    return wantarray ? $rs->all : $rs;
}

1;
