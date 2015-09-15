# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::Arp;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

use Scalar::Util qw(blessed);


sub search_by_ipaddress {
    my ($self, $ipaddress) = @_;

    if ( blessed($ipaddress)
             &&  $ipaddress->isa('Manoc::IPAddress::IPv4') )
    {
        $ipaddress = $ipaddress->padded;
    }

    return $self->search({ipaddr => $ipaddress});
}


sub search_by_ipaddress_ordered {
    shift->search_by_ipaddress(@_)->search(
	{},
	{
	    order_by => { -desc => [ 'lastseen', 'firstseen' ] }
	}
    );
}

sub search_conflicts {
    my $self = shift;

    $self->search(
        { archived => '0' },
        {
            select   => [ 'ipaddr', { count => { distinct => 'macaddr' } } ],
            as       => [ 'ipaddr', 'count' ],
            group_by => ['ipaddr'],
            having => { 'COUNT(DISTINCT(macaddr))' => { '>', 1 } },
        }
    );
}

sub search_multihomed {
    my $self = shift;

    $self->search(
        { archived => '0' },
        {
            select   => [ 'macaddr', { count => { distinct => 'ipaddr' } } ],
            as       => [ 'macaddr', 'count' ],
            group_by => ['macaddr'],
            having => { 'COUNT(DISTINCT(ipaddr))' => { '>', 1 } },
        }
    );
}

sub first_last_seen {
    my $self = shift;

    $self->search(
	{ },
	{
            select   => [
		'ipaddr',
		{ MAX => 'lastseen' },
		{ MIN => 'firstseen' },
	    ],
	    as       => [ 'ip_address', 'lastseen', 'firstseen' ],
	    group_by => [ 'ipaddr'],
	}
    );
}

1;
