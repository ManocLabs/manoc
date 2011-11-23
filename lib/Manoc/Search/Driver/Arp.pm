# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::Arp;
use Moose;
extends 'Manoc::Search::Driver';

use Manoc::Search::Item::MacAddr;
use Manoc::Search::Item::IpAddr;
use Manoc::Utils qw(padded_ipaddr);

sub build_ip_pattern{
 my ($self, $ip, $match) = @_;

 my $pattern = padded_ipaddr($ip);

 $match eq 'begin'   and $pattern = "$pattern%";
 $match eq 'end'     and $pattern = "%$pattern";
 $match eq 'partial' and $pattern = "%$pattern%";
    
 return $pattern;
}

sub search_ipaddr {
    my ( $self, $query, $result ) = @_;

    my $pattern = $self->build_ip_pattern($query->search_string, $query->match);
    my $schema  = $self->engine->schema;

    my $search = { ipaddr => { like => $pattern } };
    $query->limit and
        $search->{lastseen} = { '>' => $query->start_date };

    my $it = $schema->resultset('Arp')->search(
        $search,
        {
            select   => [ 'ipaddr', 'macaddr', { max => 'lastseen' } ],
            as       => [ 'ipaddr', 'macaddr', 'timestamp' ],
            group_by => [qw(ipaddr macaddr)]
        },
    );

    while ( my $e = $it->next ) {
        my $item = Manoc::Search::Item::MacAddr->new(
            {
                match     => $e->ipaddr,
                addr      => $e->macaddr,
                timestamp => $e->get_column('timestamp'),
            }
        );
        $result->add_item($item);
    }
}

sub search_macaddr {
    my ( $self, $query, $result ) = @_;

    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    my $search = { macaddr => { like => $pattern } };
    $query->limit and
        $search->{lastseen} = { '>' => $query->start_date };

    my $it = $schema->resultset('Arp')->search(
        $search,
        {
            select   => [ 'ipaddr', 'macaddr', { max => 'lastseen' } ],
            as       => [ 'ipaddr', 'macaddr', 'timestamp' ],
            group_by => [qw(ipaddr macaddr)]
        },
    );

    while ( my $e = $it->next ) {
        my $item = Manoc::Search::Item::IpAddr->new(
            {
                match     => $e->macaddr,
                addr      => $e->ipaddr,
                timestamp => $e->get_column('timestamp'),
            }
        );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
