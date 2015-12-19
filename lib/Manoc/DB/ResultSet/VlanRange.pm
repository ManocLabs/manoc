# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::VlanRange;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

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

    return $self->search($conditions);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

