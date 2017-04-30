package App::Manoc::DB::ResultSet::VlanRange;

use strict;
use warnings;

##VERSION

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
