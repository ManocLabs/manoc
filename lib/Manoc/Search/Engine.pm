# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Engine;

use Moose;
use Module::Pluggable::Object;

use Manoc::Search;
use Manoc::Search::QueryType;
use Manoc::Search::Result;

has driver_registry => (
    is      => 'rw',
   isa     => 'HashRef',
    default => sub { +{} },
);

has schema => ( is => 'rw', );

sub BUILD {
    my $self = shift;

    #load default searches methods
    $self->_load_drivers;
    #load plugins methods
    my @plugin_types   = Manoc::Search->_plugin_types;
    my $plugin_locator = Module::Pluggable::Object->new(
						  search_path =>  ['Manoc::Plugin'],
						  only        =>  qr/Driver$/,
						 );
    $self->_load_drivers($plugin_locator, \@plugin_types);
}

sub _load_drivers {
    my ($self, $locator, $types) = @_;
    
    $types or $types = \@Manoc::Search::QueryType::TYPES;
    $locator or  $locator = Module::Pluggable::Object->new( search_path => ['Manoc::Search::Driver'], );

    foreach my $class ( $locator->plugins ) {

        # hack stolen from catalyst:
        # don't overwrite $@ if the load did not generate an error
        my $error;
        {
            local $@;
            my $file = $class . '.pm';
            $file =~ s{::}{/}g;
            eval { CORE::require($file) };
            $error = $@;
        }
        die $error if $error;

        my $o = $class->new( { engine => $self } );
	
        foreach my $type (@{$types}) {
            $o->can("search_$type") and
                $self->_add_driver( $type, $o );
        }
    }
}

sub _add_driver {
    my ( $self, $type, $driver ) = @_;

    push @{ $self->driver_registry->{$type} }, $driver;
}

sub search {
    my ( $self, $query ) = @_;

    my $result = Manoc::Search::Result->new( { query => $query } );
    my $type = $query->query_type;

    my $drivers = $self->driver_registry->{$type};
    my $method  = "search_$type";
    foreach my $driver (@$drivers) {
        $driver->$method( $query, $result );
    }

    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;
