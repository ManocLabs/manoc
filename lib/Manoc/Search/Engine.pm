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

has schema => (
    is       => 'ro',
    required => 1,
);

has query_types => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  =>  sub { \@Manoc::Search::QueryType::TYPES },
);


sub BUILD {
    my $self = shift;

    #load default searches methods
    $self->_find_drivers;

}

sub _find_drivers {
    my ($self) = @_;

    my $locator = Module::Pluggable::Object->new( search_path => ['Manoc::Search::Driver'], );
    foreach my $class ( $locator->plugins ) {
	$self->_load_driver($class);
    }

    # TODO plugin namespace
}


sub _load_driver {
    my ($self, $class) = @_;
    
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
    foreach my $type (@{$self->query_types}) {
	$o->can("search_$type") and
	    $self->_register_driver( $type, $o );
    }
}

sub _register_driver {
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
