# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::ResultSet::VlanRange;

use strict;
use warnings;

use parent 'App::Manoc::DB::ResultSet';

sub get_overlap_ranges {
    my ( $self, $start, $end ) = @_;

    my $conditions = [
        {
            start => { '<=' => $start },
            end   => { '>=' => $start },
        },
        {
            start => { '<=' => $end },
            end   => { '>=' => $end },
        },
    ];

    return
        wantarray ? $self->search($conditions)->all :
        $self->search_rs($conditions);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
