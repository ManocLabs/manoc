package App::Manoc::DB::ResultSet::CablingMatrix;
#ABSTRACT: ResultSet class for CablingMatrix
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

sub check_connection {
    my ( $self, $from, $to ) = @_;

    # TODO
    # flexible check to verify cdp links or forms
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
