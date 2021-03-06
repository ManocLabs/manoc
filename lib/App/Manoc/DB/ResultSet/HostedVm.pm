package App::Manoc::DB::ResultSet::HostedVm;
#ABSTRACT: ResultSet class for HostedVm

=head1 DESCRIPTION

This class is needed in order to load the
L<App::Manoc::DB::Helper::ResultSet::TupleArchive> component.

=cut

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
