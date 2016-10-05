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

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
