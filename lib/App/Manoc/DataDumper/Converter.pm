package App::Manoc::DataDumper::Converter;
#ABSTRACT: Helper for reading datadumps from previous Manoc version

use Moose;

##VERSION

use Class::Load;

=attr log

A Manoc logger instance. Required.

=cut

has 'log' => (
    is       => 'ro',
    required => 1,
);

=attr schema

Manoc::DB schema. Required.

=cut

has 'schema' => (
    is       => 'ro',
    required => 1,
);

=attr from_version

Original version of dump

=cut

has 'from_version' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=attr to_version

Destination version

=cut

has 'to_version' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

# sorted by ascending version
has '_converters' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_converter => 'push',
    }
);

sub BUILD {
    my ($self) = @_;

    $self->_load_converters;
}

sub _load_converters {
    my ($self) = @_;

    my $first_converter = $self->from_version;
    my $last_converter  = $self->to_version - 1;

    for my $v ( $first_converter .. $last_converter ) {
        my $class_name = "v$v";
        $self->log->info("Loading converter $class_name");
        $class_name = "App::Manoc::DataDumper::Converter::$class_name";
        Class::Load::load_class($class_name) or return;

        my $c = $class_name->new( log => $self->log, schema => $self->schema );
        $self->add_converter($c);
    }
}

=method get_table_name( $source_name )

Return the table to load corresponding to DB source C<$source_name>.

=cut

sub get_table_name {
    my ( $self, $source_name ) = @_;

    my $method_name = "get_table_name_${source_name}";

    # get name from lowest converter
    foreach my $c ( @{ $self->_converters } ) {
        next unless $c->can($method_name);
        my $name = $c->$method_name();
        $name and return $name;
    }
}

=method get_table_name( $source_name )

Return the table name (or a reference to a name list) to be used
to refine data imported into DB source C<$source_name>.

=cut

sub get_additional_table_name {
    my ( $self, $source_name ) = @_;

    my $method_name = "get_additional_table_name_${source_name}";

    # get name from lowest converter
    foreach my $c ( @{ $self->_converters } ) {
        next unless $c->can($method_name);
        my $name = $c->$method_name();
        $name and return $name;
    }
}

=method upgrade_table( \@data, $name )

Apply any needed transformation to records in @data for table C<$name>.

=cut

sub upgrade_table {
    my ( $self, $data, $name ) = @_;

    my $method_name = "upgrade_$name";

    # use all converters
    $self->log->info("Running converters for $name");
    foreach my $c ( @{ $self->_converters } ) {
        next unless $c->can($method_name);
        $c->$method_name($data);
    }
}

=method process_additional_table( \@data, $source_name, $table_name )

Prepare @data coming from $table_name in order to be used to further
refine already imported records in $source_name.

=cut

sub process_additional_table {
    my ( $self, $data, $source_name, $table_name ) = @_;

    my $method_name = "process_additional_table_${source_name}_${table_name}";

    # use all converters
    $self->log->info("Running additional converters for $table_name -> $source_name");
    foreach my $c ( @{ $self->_converters } ) {
        next unless $c->can($method_name);
        $c->$method_name($data);
    }
}

=method after_import_source( $source )

To be called after having imported all data for data source C<$source>.

=cut

sub after_import_source {
    my ( $self, $source ) = @_;

    my $source_name = $source->source_name;
    my $method_name = "after_import_${source_name}";

    $self->log->info("Running after import callbacks");
    foreach my $c ( @{ $self->_converters } ) {
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
