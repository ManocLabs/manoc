package App::Manoc::DB::ResultSet::ServerHWNIC;
#ABSTRACT: ResultSet class for ServerHWNIC
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::Iface;

=method search_not_cabled( $server )

Return a resultset containing all NICs belonging to $server which are not
in the cabling matrix.

=cut

sub search_not_cabled {
    my ( $self, $server ) = @_;

    my $conditions = { 'cabling.hwserver_nic_id' => undef };
    $server and $conditions->{'me.server_id'} = $server;

    my $rs = $self->search(
        $conditions,
        {
            alias => 'me',
            join  => 'cabling',
        }
    );
    return wantarray ? $rs->all : $rs;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
