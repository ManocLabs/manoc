package App::Manoc::DB::ResultSet::Arp;
#ABSTRACT: ResultSet class for Arp

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::Arp;

use Scalar::Util qw(blessed);

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

=method search_by_ipaddress( $ipaddress )

Search all entries for C<$ipaddress> which can be a string (in padded format)
or a L<App::Manoc::IPAddress::IPv4> object.

=cut

sub search_by_ipaddress {
    my ( $self, $ipaddress ) = @_;

    if ( blessed($ipaddress) &&
        $ipaddress->isa('App::Manoc::IPAddress::IPv4') )
    {
        $ipaddress = $ipaddress->padded;
    }

    my $rs = $self->search( { ipaddr => $ipaddress } );
    return wantarray ? $rs->all : $rs;
}

=method search_by_ipaddress_ordered( $ipaddress )

Same as C<search_by_ipaddress> bur ordered by lastseen and firstseen.

=cut

sub search_by_ipaddress_ordered {
    my $rs = shift->search_by_ipaddress(@_)->search(
        {},
        {
            order_by => { -desc => [ 'lastseen', 'firstseen' ] }
        }
    );
    return wantarray ? $rs->all : $rs;

}

=method search_conflicts

Return a list of IP address which have more than one active associated mac
address. A column count contains the number of those mac addresses

=cut

sub search_conflicts {
    my $self = shift;

    my $rs = $self->search(
        { archived => '0' },
        {
            select   => [ 'ipaddr', { count => { distinct => 'macaddr' } } ],
            as       => [ 'ipaddr', 'count' ],
            group_by => ['ipaddr'],
            having => { 'COUNT(DISTINCT(macaddr))' => { '>', 1 } },
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method search_multihomed

Return a list of mac addresses which have more than one active associated IP
address. A column count contains the number of those IP addresses.

=cut

sub search_multihomed {
    my $self = shift;

    my $rs = $self->search(
        { archived => '0' },
        {
            select   => [ 'macaddr', { count => { distinct => 'ipaddr' } } ],
            as       => [ 'macaddr', 'count' ],
            group_by => ['macaddr'],
            having => { 'COUNT(DISTINCT(ipaddr))' => { '>', 1 } },
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method first_last_seen

Return for each IP address (returned as a column C<ip_address>) the minimun
firstseen value and the maximum lastseen.

=cut

sub first_last_seen {
    my $self = shift;

    my $rs = $self->search(
        {},
        {
            select => [ 'ipaddr', { MAX => 'lastseen' }, { MIN => 'firstseen' }, ],
            as       => [ 'ip_address', 'lastseen', 'firstseen' ],
            group_by => ['ipaddr'],
        }
    );
    return wantarray ? $rs->all : $rs;
}

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

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $type    = $query->query_type;
    my $pattern = $query->sql_pattern;

    my $filter = {};
    if ( $type eq 'ipaddr' ) {
        $filter->{ipaddr} = { like => $pattern };
    }
    elsif ( $type eq 'macaddr' ) {
        $filter->{macaddr} = { like => $pattern };
    }
    else {
        return;
    }

    $query->limit and
        $filter->{lastseen} = { '>' => $query->start_date };

    my $rs = $self->search(
        $filter,
        {
            select   => [ 'ipaddr', 'macaddr', { max => 'lastseen' } ],
            as       => [ 'ipaddr', 'macaddr', 'timestamp' ],
            group_by => [qw(ipaddr macaddr)]
        },
    );

    if ( $type eq 'ipaddr' ) {
        while ( my $e = $rs->next ) {
            $result->add_item(
                App::Manoc::DB::Search::Result::Arp->new(
                    {
                        match      => $e->ipaddr->unpadded,
                        macaddress => $e->macaddr,
                        ipaddress  => $e->ipaddr,
                        timestamp  => $e->get_column('timestamp'),
                    }
                )
            );
        }
    }
    elsif ( $type eq 'macaddr' ) {
        while ( my $e = $rs->next ) {
            $result->add_item(
                App::Manoc::DB::Search::Result::Arp->new(
                    {
                        match      => $e->macaddr,
                        macaddress => $e->macaddr,
                        ipaddress  => $e->ipaddr,
                        timestamp  => $e->get_column('timestamp'),
                    }
                )
            );
        }
    }
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
