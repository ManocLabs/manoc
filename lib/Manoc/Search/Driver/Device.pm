# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::Device;
use Moose;
use Manoc::Search::Item::Device;

extends 'Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    return $self->search_device( $query, $result );
}

sub search_device {
    my ( $self, $query, $result ) = @_;
    my $rs = $self->_search_addr($query);

    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Device->new(
            {
                device => $e,
                match  => $e->id->address,
            }
        );
        $result->add_item($item);
      }

    $rs = $self->_search_name($query);
    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Device->new(
            {
                device => $e,
                match  => $e->name,
            }
        );
        $result->add_item($item);
    }
}

sub search_ipaddr {
    my ( $self, $query, $result ) = @_;
    my $rs = $self->_search_addr($query);

    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Device->new(
            {
                device => $e,
                match  => $e->id->address,
            }
        );
        $result->add_item($item);
    }
}

sub _search_addr {
    my ( $self, $query ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;
    return $schema->resultset('Device')->search(
        {'mng_address' => { -like => $pattern }},
        { order_by => ['name'] },
	);
}

sub _search_name {
    my ( $self, $query ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;
    return $schema->resultset('Device')->search(
						{name => { -like => $pattern }},
						{ order_by => 'name' },
					       );
}

sub search_note {
  my ( $self, $query, $result ) = @_;
  my $pattern = $query->sql_pattern;
  my $schema  = $self->engine->schema;
  
  my $rs = $schema->resultset('Device')->search({notes => { -like => $pattern }},
						{ order_by => ['name'] },
					       );
  
  while ( my $e = $rs->next ) {
    my $item = Manoc::Search::Item::Device->new(
						{
						 device => $e,
						 match  => $e->id->address,
						 notes  => $e->notes,
						}
					       );
    $result->add_item($item);
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
