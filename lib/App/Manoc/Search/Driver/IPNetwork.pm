# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Driver::IPNetwork;
use Moose;

use App::Manoc::Search::Item::IPNetwork;
use App::Manoc::Search::Item::IpCalc;
use App::Manoc::IPAddress::IPv4;
use App::Manoc::Utils::IPAddress qw(check_addr);

extends 'App::Manoc::Search::Driver';

sub search_subnet {
    my ( $self, $query, $result ) = @_;
    my $subnet = $query->subnet;
    my $prefix = $query->prefix;
    my $schema = $self->engine->schema;

    # if subnet isn't defined, the scope is specified
    # by the user
    $subnet = $query->sql_pattern unless ( defined($subnet) );

    return unless ( check_addr($subnet) );
    $prefix = '24' unless ( defined($prefix) );

    my $addr = App::Manoc::IPAddress::IPv4->new($subnet);

    my $filter = { address => $addr };
    $prefix and $filter->{prefix} = $prefix;

    my @networks = $schema->resultset('IPRange')->search($filter);

    if (@networks) {
        foreach my $e (@networks) {
            my $item = App::Manoc::Search::Item::IPNetwork->new(
                {
                    name    => $e->name,
                    id      => $e->id,
                    network => $e->address . "/" . $e->prefix,
                    match   => $e->name,
                }
            );
            $result->add_item($item);
        }
    }
    else {

        # no results, use IPCalc
        $prefix //= 24;

        my $item = App::Manoc::Search::Item::IpCalc->new(
            {
                prefix  => $prefix,
                network => $subnet,
                match   => "$subnet/$prefix",
            }
        );
        $result->add_item($item);
        return;
    }
}

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    $it = $schema->resultset('IPNetwork')
        ->search( { name => { '-like' => $pattern } }, { order_by => 'name' } );

    while ( $e = $it->next ) {
        my $item = App::Manoc::Search::Item::IPNetwork->new(
            {
                name    => $e->name,
                id      => $e->id,
                network => $e->network->_stringify,
                match   => $e->name,
            }
        );
        $result->add_item($item);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
