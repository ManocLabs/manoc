package App::Manoc::DB::ResultSet::ServerHWNIC;
#ABSTRACT: ResultSet class for ServerHWNIC
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::Iface;

=method search_not_cabled( )

Return a resultset containing all NICs which are not in the cabling matrix.

=cut

sub search_uncabled {
    my ( $self, $args ) = @_;

    my $search_opts = {
        alias    => 'me',
        prefetch => ['cabling']
    };
    my $conditions = { 'cabling.hwserver_nic_id' => undef };

    my $rs = $self->search( $conditions, $search_opts );
    return wantarray ? $rs->all : $rs;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
