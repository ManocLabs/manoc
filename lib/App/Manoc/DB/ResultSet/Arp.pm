# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::ResultSet::Arp;
use strict;
use warnings;

use parent 'App::Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

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

sub search_by_ipaddress_ordered {
    my $rs = shift->search_by_ipaddress(@_)->search(
        {},
        {
            order_by => { -desc => [ 'lastseen', 'firstseen' ] }
        }
    );
    return wantarray ? $rs->all : $rs;

}

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

sub register_tuple {
    my $self   = shift;
    my %params = @_;

    my $ipaddr = $params{ipaddr};
    $ipaddr = App::Manoc::IPAddress::IPv4->new( $params{ipaddr} )
        unless blessed( $params{ipaddr} );
    $params{ipaddr} = $ipaddr->padded;

    $self->next::method(%params);
}

1;
