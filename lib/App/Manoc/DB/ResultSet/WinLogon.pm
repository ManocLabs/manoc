package App::Manoc::DB::ResultSet::WinLogon;
#ABSTRACT: ResultSet class for WinLogon

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

use App::Manoc::DB::Search::Result::Logon;

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

=method register_tuple( %params )

Overridden in order to convert $params{ipaddr} to
L<App::Manoc::IPAddress::IPv4> if needed.

=cut

sub register_tuple {
    my $self   = shift;
    my %params = @_;

    my $ipaddr = $params{ipaddr};
    $ipaddr = App::Manoc::IPAddress::IPv4->new( $params{ipaddr} )
        unless blessed( $params{ipaddr} );
    $params{ipaddr} = $ipaddr->padded;

    $self->next::method(%params);
}

=method manoc_search( $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $query_type = $query->query_type;

    return unless $query_type eq 'logon';

    my $pattern = $query->sql_pattern;

    my $conditions = {};
    $conditions->{'user'} = { '-like', $pattern };
    if ( $query->limit ) {
        $conditions->{lastseen} = { '>=', $query->start_date };
    }

    my $rs = $self->search(
        $conditions,
        {
            select   => [ 'user', 'ipaddr', { max => 'lastseen' } ],
            as       => [ 'user', 'ipaddr', 'lastseen' ],
            group_by => 'ipaddr',
        }
    );

    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Logon->new(
            {
                username  => $e->user,
                match     => lc( $e->user ),
                ipaddress => $e->ipaddr,
                timestamp => $e->get_column('lastseen'),
            }
        );
        $result->add_item($item);
    }
}
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
