package App::Manoc::DB::ResultSet::WorkstationHW;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

sub unused {
    my ($self) = @_;

    my $used_asset_ids = $self->result_source->schema->resultset('Workstation')->search(
        {
            'subquery.decommissioned'   => 0,
            'subquery.workstationhw_id' => { -is_not => undef }
        },
        {
            alias => 'subquery',
        }
    )->get_column('workstationhw_id');

    my $me     = $self->current_source_alias;
    my $assets = $self->search(
        {
            'hwasset.location' =>
                { '!=' => App::Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED },
            "$me.id" => {
                -not_in => $used_asset_ids->as_query,
            }
        },
        {
            join => 'hwasset',
        }
    );

    return $assets;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
