package App::Manoc::DB::ResultSet::CablingMatrix;
#ABSTRACT: ResultSet class for CablingMatrix
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

=method check_connection

EXPERIMENTAL Flexible check to verify cdp links or forms

=cut

sub check_connection {
    my ( $self, $from, $to ) = @_;

    # TODO
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
