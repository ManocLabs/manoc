package App::Manoc::Search::Engine;

use Moose;

##VERSION

use Module::Pluggable::Object;

use App::Manoc::Search;
use App::Manoc::Search::QueryType;
use App::Manoc::Search::Result;

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
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { \@App::Manoc::Search::QueryType::TYPES },
);

sub BUILD {
    my $self = shift;

    #load default searches methods
    $self->_find_drivers;

}

sub _find_drivers {
    my ($self) = @_;

    my $locator =
        Module::Pluggable::Object->new( search_path => ['App::Manoc::Search::Driver'], );
    foreach my $class ( $locator->plugins ) {
        $self->_load_driver($class);
    }

    # TODO plugin namespace
}

sub _load_driver {
    my ( $self, $class ) = @_;

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
    foreach my $type ( @{ $self->query_types } ) {
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

    my $result = App::Manoc::Search::Result->new( { query => $query } );
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
