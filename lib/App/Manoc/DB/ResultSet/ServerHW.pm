package App::Manoc::DB::ResultSet::ServerHW;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Result::HWAsset;

sub unused {
    my ($self) = @_;

    my $used_asset_ids = $self->result_source->schema->resultset('Server')->search(
        {
            'subquery.decommissioned' => 0,
            'subquery.serverhw_id'    => { -is_not => undef }
        },
        {
            alias => 'subquery',
        }
    )->get_column('serverhw_id');

    my $me = $self->current_source_alias;
    my $rs = $self->search(
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
    return wantarray ? $rs->all : $rs;

}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
