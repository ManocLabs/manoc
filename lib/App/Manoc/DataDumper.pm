package App::Manoc::DataDumper;
#ABSTRACT: Data dumper for import/export in Manoc
use Moose;

##VERSION

use App::Manoc::DB;
use App::Manoc::DataDumper::Converter;

use DBIx::Class::ResultClass::HashRefInflator;

use Try::Tiny;

my $ROWS            = 100000;
my $LOAD_BLOCK_SIZE = 5000;

my $SOURCE_DEPENDECIES = {
    'Server  '       => [ 'ServerHW', 'VirtualMachine' ],
    'VirtualMachine' => 'VirtualInfr',
    'ServerHW'       => 'HWAsset',
    'Device'         => 'HWAsset',
    'HWAsset'        => 'Rack',
    'Rack'           => 'Building',
    'Mat'            => 'Device',
    'IfStatus'       => 'Device',
    'IfNotes'        => 'Device',
    'CDPNeigh'       => 'Device',
    'DeviceConfig'   => 'Device',
    'DeviceNWInfo'   => 'Device',
    'Uplink'         => 'Device',
    'SSIDList'       => 'Device',
    'Dot11Assoc'     => 'Device',
    'Dot11Client'    => 'Device',
    'DiscoveredHost' => 'DiscoverSession',
};

has 'filename' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'config' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 0,
);

has 'schema' => (
    is       => 'ro',
    required => 1,
);

has 'log' => (
    is       => 'ro',
    required => 1,
);

has 'include' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'exclude' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'skip_notempty' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'version' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_version',
);

has 'source_names' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_source_names'
);

sub _build_version {
    my $self = shift;
    return App::Manoc::DB::get_version;
}

sub _build_source_names {
    my $self = shift;
    my @sources;

    my @include_list = @{ $self->include };
    my @exclude_list = @{ $self->exclude };

    @sources = scalar(@include_list) ? @include_list : $self->schema->sources;

    if ( scalar(@exclude_list) ) {
        my %filter = map { $_ => 1 } @exclude_list;
        @sources = grep { !$filter{$_} } @sources;
    }

    return $self->_order_sources( \@sources );
}

sub _order_sources {
    my ( $self, $sources ) = @_;

    my %set = map { $_ => 1 } @$sources;
    my @ordered_list;

    my $connections_to = {};
    while ( my ( $from, $deps ) = each %$SOURCE_DEPENDECIES ) {
        ref($deps) eq 'ARRAY' or $deps = [$deps];
        foreach my $to (@$deps) {
            $set{$from} or next;
            $set{$to}   or next;
            $connections_to->{$from}->{$to} = 1;
        }
    }

    while (%set) {
        my ($start_node) =
            grep { !$connections_to->{$_} || !%{ $connections_to->{$_} } }
            keys %set;

        if ( !$start_node ) {
            die "circular dependency found";
        }

        push @ordered_list, $start_node;
        delete $set{$start_node};
        delete $connections_to->{$_}->{$start_node} for keys %$connections_to;
    }
    return \@ordered_list;
}

#----------------------------------------------------------------------#
#                      L O A D   A C T I O N                           #
#----------------------------------------------------------------------#

sub _load_tables_loop {
    my ( $self, $datadump, $file_set, $overwrite, $force ) = @_;
    my $converter;

    # try to load a converter if needed
    my $version = $datadump->metadata->{'version'};

    # convert old version formats to DB version
    $version eq '2.000000' and $version = 2;
    $version eq '20121115' and $version = 3;

    if ( $version < $self->version ) {
        $converter = App::Manoc::DataDumper::Converter->new(
            log          => $self->log,
            schema       => $self->schema,
            from_version => $version,
            to_version   => $self->version,
        );
    }

    my $source_names = $self->source_names;
    foreach my $source_name (@$source_names) {
        my $source = $self->schema->source($source_name);
        next unless $source->isa('DBIx::Class::ResultSource::Table');

        if ( $self->skip_notempty and $source->resultset->count() ) {
            $self->log->info("Source $source_name is not empty, skip.");
            next;
        }

        if ($overwrite) {
            $self->log->debug("Cleaning $source_name");
            $source->resultset->delete();
        }

        $self->log->debug("Loading $source_name");

        my $tables;
        $converter and $tables = $converter->get_table_name($source_name);
        $tables ||= [ $source->from ];
        ref($tables) eq 'ARRAY' or $tables = [$tables];

        foreach my $table (@$tables) {
            $self->log->debug("Loading $source_name from $table");

            my @filenames = grep( /^$table\./, keys %{$file_set} );
            if ( @filenames > 1 ) {
                # sort by page
                @filenames =
                    map  { $_->[0] }
                    sort { $a->[1] <=> $b->[1] }
                    map  { [ $_, /\.(\d+)/ ] } @filenames;
            }

            foreach my $filename (@filenames) {
                $self->log->debug("Loading $filename");

                #load in RAM all the table records
                my $records = $datadump->load_file($filename);
                if ( !$records ) {
                    $self->log->info("File $filename not found, skipping");
                    next;
                }

                my $count = scalar(@$records);
                $self->log->info("Read $count records from $filename");
                unless ($count) {
                    $self->log->info("Skipped empy file $filename");
                    next;
                }

                # convert records if needed
                $converter and
                    $converter->upgrade_table( $records, $table );

                # converter callback
                $converter and
                    $converter->upgrade_table( $records, $source_name );

                # load into db
                $self->_load_table( $source, $records, $force );

                #free memory
                undef @$records;
                undef $records;
            }
        }
        # converter callback
        $converter and
            $converter->after_import_source($source);

    }
}

sub _load_table {
    my ( $self, $source, $records, $force ) = @_;

    my $rs = $source->resultset;
    $self->log->debug("loading table");

    my $count      = 0;
    my $block_size = $LOAD_BLOCK_SIZE;
    my $offset     = 0;

    while ( $offset < @$records - 1 ) {
        my $last_record_index = $offset + $block_size - 1;
        $last_record_index > @$records - 1 and $last_record_index = @$records - 1;

        my $data = [ @$records[ $offset .. $last_record_index ] ];

        try {
            $self->log->debug( "populate $offset, $last_record_index - " . scalar(@$data) );
            $rs->populate($data);
        }
        catch {
            if ($force) {
                $self->log->debug("forcing populate offset=$offset");
                foreach my $row (@$data) {
                    try {
                        $rs->populate( [$row] );
                    }
                    catch {
                        $count++;
                        $self->log->debug("Recovering error: $_");

                    };
                }
            }
            else {
                $self->log->logdie("Fatal error: $_");
            }
        };

        $offset += $block_size;
    }

    $self->log->error("Warning: $count errors ignored!") if ($count);
    $self->log->info( scalar(@$records) - $count, " records loaded in table " . $source->name );
}

=method load( $enable_fk, $overwrite, $force )

Load data from C<$self->filename>.

=for: list

* If C<$enable_fk> is true foreign key are checked while data is
loading, otherwise use deferred foreign key checks.

* If C<$overwrite> is true old data is deleted before loading new.

* If C<$force> is true data loading continues even if an error condition arise.

=cut

sub load {
    my ( $self, $enable_fk, $overwrite, $force ) = @_;

    my $datadump = App::Manoc::DataDumper::Data->load( $self->filename );

    if ( !defined($datadump) ) {
        $self->log->fatal( "cannot open ", $self->filename );
        return;
    }

    #filter metadata file from sources
    my $file_set = { map { $_ => 1 } @{ $datadump->filelist } };

    my $source_names = $self->source_names;
    $self->log->debug( 'Sources: ', join( ',', @$source_names ) );

    if ($enable_fk) {
        $self->_load_tables_loop( $datadump, $file_set, $overwrite, $force );
    }
    else {
        # force loading the correct storage backend before
        # calling with_deferred_fk_checks
        $self->schema->storage->ensure_connected();

        $self->schema->storage->with_deferred_fk_checks(
            sub {
                $self->_load_tables_loop( $datadump, $file_set, $overwrite, $force );
            }
        );
    }
    $self->log->info("Database restored!");
}

#----------------------------------------------------------------------#
#                      S A V E   A C T I O N                           #
#----------------------------------------------------------------------#

=method save

Save Manoc data to C<$self->filename>.

=cut

sub save {
    my ($self) = @_;

    my $datadump = App::Manoc::DataDumper::Data->init( $self->filename, $self->version,
        $self->config->{DataDumper} );
    my $path_to_tar = $self->config->{DataDumper}->{path_to_tar} || undef;
    my $source_names = $self->source_names;

    foreach my $source_name (@$source_names) {
        my $source = $self->schema->resultset($source_name);
        next unless $source->isa('DBIx::Class::ResultSet');

        my $table = $source->result_source->name;
        $self->log->debug("Processing table $table");
        $self->schema->storage->dbh_do( \&_dump_table, $self->log, $datadump, $source, $ROWS );
        $self->log->info("Table $table dumped");
    }

    $self->log->debug("Writing the archive...");
    defined($path_to_tar) and $self->log->debug("use system tar in $path_to_tar ");

    $datadump->save;
    $self->log->info("Database dumped.");

}

sub _dump_table {
    my ( $storage, $dbh, $log, $datadump, $source, $rows ) = @_;
    my $table = $source->result_source->name;

    my $n_entries = $source->count;

    $source->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return unless $n_entries > 0;

    if ( $n_entries <= $ROWS ) {
        my @data     = $source->all;
        my $filename = "$table.yaml";
        $datadump->add_file( $filename, \@data );
        $log->debug("saved $filename");
        return;
    }

    # split data in files of $ROWS records
    # to optimize arrays usage set $#array=n to preallocate storage
    # creating an array of n undefs then clear the array to be
    # able to use push the normal way:

    my $page = 1;
    my @data;
    $#data = $n_entries;
    @data  = ();
    my $rs = $source->search();
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    while ( my $entry = $rs->next ) {
        push @data, $entry;

        if ( @data == $ROWS ) {
            my $filename = "$table.$page.yaml";
            $datadump->add_file( $filename, \@data );
            $log->debug("saved $filename");
            @data = ();
            $page++;
        }
    }

    # save last page
    my $filename = "$table.$page.yaml";
    $datadump->add_file( $filename, \@data );
    $log->debug("saved $filename");
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
