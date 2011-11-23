# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::IpRange;
use Moose;
use Manoc::Search::Item::IpRange;
use Manoc::Search::Item::IpCalc;
use Manoc::Utils qw(netmask_prefix2range netmask2prefix ip2int int2ip check_addr padded_ipaddr);

extends 'Manoc::Search::Driver';

sub search_subnet {
    my ( $self, $query, $result ) = @_;
    my $subnet = $query->subnet;
    my $prefix = $query->prefix;
    my $schema = $self->engine->schema;

    #if subnet isn't defined, the scope is specified
    #by the user and maybe there missing prefix parameter
    $subnet = $query->sql_pattern unless ( defined($subnet) );
    return unless ( check_addr($subnet) );
    $prefix = '24' unless ( defined($prefix) );

    my ( $from_addr, $to_addr ) = Manoc::Utils::netmask_prefix2range( $subnet, $prefix );


    my $from_addr_pad = padded_ipaddr(int2ip($from_addr));
    my $to_addr_pad   = padded_ipaddr(int2ip($to_addr));


    my @ranges = $schema->resultset('IPRange')->search(
        {
            -and => [
                'from_addr' => $from_addr_pad,
                'to_addr'   => $to_addr_pad
            ]
        }
    );
    if ( @ranges == 0 ) {
        @ranges = $schema->resultset('IPRange')->search(
            {
                -and => [
                    'from_addr' => $from_addr_pad,
                    'to_addr'   => { '<=' => $to_addr_pad }
                ]
            }
        );
    }

    if ( @ranges == 0 ) {
        my $item = Manoc::Search::Item::IpCalc->new(
            {
                prefix  => $prefix,
                iprange => $subnet,
                match   => "$subnet/$prefix",
            }
        );
        $result->add_item($item);
        return;
    }

    foreach my $e (@ranges) {
        my $item = Manoc::Search::Item::IpRange->new(
            {
                name    => $e->name,
                iprange => $e->from_addr,
                match   => $e->name,
            }
        );
        $result->add_item($item);
    }

}

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    $it = $schema->resultset('IPRange')->search(
        name => { '-like' => $pattern },
        { order_by => 'name' }
    );

    while ( $e = $it->next ) {
        my $desc =
            $e->network ? $e->network . '/' . Manoc::Utils::netmask2prefix( $e->netmask ) :
                          $e->from_addr . '-' . $e->to_addr;

        my $item = Manoc::Search::Item::IpRange->new(
            {
                name    => $e->name,
                iprange => $desc,
                match   => $e->name
            }
        );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
