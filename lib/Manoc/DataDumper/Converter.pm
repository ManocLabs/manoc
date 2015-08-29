# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Converter;

use Moose;
use Class::Load;

has 'log' => (
    is       => 'ro',
    required => 1,
);

has 'schema' => (
    is       => 'ro',
    required => 1,
);

has 'from_version' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'to_version' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

# sorted by ascending version
has 'converters' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
         add_converter => 'push',
     }
);


sub BUILD {
    my ( $self ) = @_;

    $self->_load_converters;
}

sub _load_converters {
    my ( $self ) = @_;

    my $first_converter = $self->from_version;
    my $last_converter = $self->to_version - 1;

    for my $v ( $first_converter .. $last_converter ) {
        my $class_name = "v$v";
        $self->log->info("Loading converter $class_name");
        $class_name = "Manoc::DataDumper::Converter::$class_name";
        Class::Load::load_class($class_name) or return undef;

        my $c = $class_name->new(log => $self->log, schema => $self->schema);
        $self->add_converter($c);
    }
}

sub get_table_name {
    my ($self, $source_name) = @_;

    my $method_name = "get_table_name_${source_name}";

    # get name from lowest converter
    foreach my $c (@{$self->converters}) {
        next unless $c->can($method_name);
        my $name = $c->$method_name();
        $name and return $name;
    }
}

sub upgrade_table {
    my ( $self, $data, $name ) = @_;

    my $method_name = "upgrade_$name";

    # use all converters
    $self->log->info("Running converters for $name");
    foreach my $c (@{$self->converters}) {
        next unless $c->can($method_name);
        $c->$method_name($data);
    }
}

sub after_import_source {
    my ( $self, $source) = @_;

    my $source_name = $source->source_name;
    my $method_name = "after_import_${source_name}";

    $self->log->info("Running after callbacks for source $source");
    foreach my $c (@{$self->converters}) {
        next unless $c->can($method_name);
        $c->$method_name($source);
    }
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
