# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::Server;
use Moose;
use Manoc::Search::Item::Server;

extends 'Manoc::Search::Driver';

sub search_inventory {
    shift->search_server(@_);
}

sub search_server {
    my ( $self, $query, $result ) = @_;

    my $rs = $self->_search_addr($query);
    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Server->new(
            {
                server => $e,
                match  => $e->address->address,
            }
        );
        $result->add_item($item);
    }

    $rs = $self->_search_name($query);
    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Server->new(
            {
                server => $e,
                match  => $e->hostname,
            }
        );
        $result->add_item($item);
    }
}

sub search_ipaddr {
    my ( $self, $query, $result ) = @_;
    my $rs = $self->_search_addr($query);

    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Server->new(
            {
                server => $e,
                match  => $e->address->address,
            }
        );
        $result->add_item($item);
    }
}

sub _search_addr {
    my ( $self, $query ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;
    return $schema->resultset('Server')
        ->search( { 'address' => { -like => $pattern } }, { order_by => ['name'] }, );
}

sub _search_name {
    my ( $self, $query ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;
    return $schema->resultset('Server')
        ->search( { hostname => { -like => $pattern } }, { order_by => 'name' }, );
}

no Moose;
__PACKAGE__->meta->make_immutable;
