# Copyright 2011-2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::ServerHW;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;


sub new_result {
    my ( $class, $attrs ) = @_;

    my $item = $class->next::method($attrs);

    if (! defined($item->hwasset)) {
        $item->hwasset(
            $item->new_related('hwasset', {
                type      => Manoc::DB::Result::HWAsset->TYPE_SERVER,
                location  => Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE,
                model     => $attrs->{model},
                vendor    => $attrs->{vendor},
                inventory => $attrs->{inventory},
            }));
    }
    return $item;
};

sub unused {
    my ( $self ) = @_;

    my $used_asset_ids = $self->result_source->schema->resultset('Server')
        ->search({
            dismissed => 0,
            serverhw_id  => { -is_not => undef }
        })
        ->get_column('serverhw_id');

    my $assets = $self->search(
        {
            'hwasset.location' => { '!=' => Manoc::DB::Result::HWAsset::LOCATION_DISMISSED },
            id =>  {
                -not_in => $used_asset_ids->as_query,
            }
        },
        {
            join     => 'hwasset',
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
