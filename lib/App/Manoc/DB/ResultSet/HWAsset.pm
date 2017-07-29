package App::Manoc::DB::ResultSet::HWAsset;
#ABSTRACT: ResultSet class for HWAsset

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::Row;
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

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $type    = $query->query_type;
    my $pattern = $query->sql_pattern;

    return unless $type eq 'inventory';

    foreach my $col (qw (serial inventory)) {
        my $rs = $self->search( { $col => { -like => $pattern } }, { order_by => 'name' } );

        while ( my $e = $rs->next ) {
            my $item = App::Manoc::DB::Search::Result::Row->new(
                {
                    row   => $e,
                    match => $e->$col,
                }
            );
            $result->add_item($item);
        }
    }

}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
