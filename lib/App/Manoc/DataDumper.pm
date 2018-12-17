package App::Manoc::DataDumper;
#ABSTRACT: Data dumper for import/export in Manoc
use Moose;

##VERSION

=head1 SYNOPSYS

Parameters:

=for: list

* If C<$enable_fk> is true foreign key are checked while data is
loading, otherwise use deferred foreign key checks.

* If C<$overwrite> is true old data is deleted before loading new.

* If C<$force> is true data loading continues even if an error condition arise.

=cut

use App::Manoc::DB;
use App::Manoc::DataDumper::Converter;

use DBIx::Class::ResultClass::HashRefInflator;

use Try::Tiny;

my $ROWS            = 100000;
my $LOAD_BLOCK_SIZE = 5000;

my $SOURCE_DEPENDECIES = {
    'Server  '        => [ 'ServerHW', 'VirtualMachine' ],
    'DHCPReservation' => 'DHCPServer',
    'DHCPLease'       => 'DHCPServer',
    'VirtualMachine'  => 'VirtualInfr',
    'ServerHW'        => 'HWAsset',
    'Device'          => 'HWAsset',
    'HWAsset'         => 'Rack',
    'Rack'            => 'Building',
    'Mat'             => 'Device',
    'DeviceIfStatus'  => 'DeviceIface',
    'DeviceIface'     => 'Device',
    'CDPNeigh'        => 'Device',
    'DeviceConfig'    => 'Device',
    'DeviceNWInfo'    => [ 'Device', 'Credentials' ],
    'Credentials'     => 'Device',
    'Uplink'          => 'Device',
    'SSIDList'        => 'Device',
    'Dot11Assoc'      => 'Device',
    'Dot11Client'     => 'Device',
    'DiscoveredHost'  => 'DiscoverSession',
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

has 'enable_fk' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'overwrite' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'force' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
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

sub _load_sources {
    my ( $self, $datadump ) = @_;
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

    if ( $self->overwrite ) {
        foreach my $source_name ( reverse @$source_names ) {
            my $source = $self->schema->source($source_name);

            $self->log->debug("Cleaning $source_name");
            $source->resultset->delete();
        }
    }

    foreach my $source_name (@$source_names) {
        my $source = $self->schema->source($source_name);
        next unless $source->isa('DBIx::Class::ResultSource::Table');

        if ( $self->skip_notempty and $source->resultset->count() ) {
            $self->log->info("Source $source_name is not empty, skip.");
            next;
        }

        $self->log->debug("Loading $source_name");

        my $tables;
        $converter and $tables = $converter->get_table_name($source_name);
        $tables ||= [ $source->from ];
        ref($tables) eq 'ARRAY' or $tables = [$tables];

        foreach my $table (@$tables) {

            my $records_callback = sub {
                my $records = shift;

                # convert records if needed
                $converter and
                    $converter->upgrade_table( $records, $table );

                # converter callback
                $converter and
                    $converter->upgrade_table( $records, $source_name );

                # load into db
                $self->_populate_records( $source, $records );

            };

            $self->log->debug("Loading $table");
            $self->_load_table_files( $datadump, $table, $records_callback );
        }

        my $additional_tables;
        $converter and $additional_tables = $converter->get_additional_table_name($source_name);
        if ($additional_tables) {
            ref($additional_tables) eq 'ARRAY' or $additional_tables = [$additional_tables];

            foreach my $table (@$additional_tables) {

                my $additional_table_cb = sub {
                    my $records = shift;

                    # convert records if needed
                    $converter and
                        $converter->upgrade_table( $records, $table );

                    # prepare records for update
                    $converter and
                        $converter->process_additional_table( $records, $source_name, $table );

                    $self->_update_records( $source, $records );
                };
                $self->log->debug("Loading additional $table");
                $self->_load_table_files( $datadump, $table, $additional_table_cb );
            }
        }

        # converter final callback
        $converter and
            $converter->after_import_source($source);

    }
}

# return an ordered list of the files in which $table has been saved
sub _get_table_filenames {
    my ( $self, $datadump, $table ) = @_;

    my @filenames = grep( /^$table\./, @{ $datadump->filelist } );
    if ( @filenames > 1 ) {
        # sort by page
        @filenames =
            map  { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map  { [ $_, /\.(\d+)/ ] } @filenames;
    }

    return @filenames;
}

sub _load_table_files {
    my ( $self, $datadump, $table, $callback ) = @_;

    my @filenames = $self->_get_table_filenames( $datadump, $table );

    foreach my $filename (@filenames) {
        $self->log->debug("Loading $table from $filename");

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

        $callback->($records);

        #free memory
        undef @$records;
        undef $records;
    }
}

sub _populate_records {
    my ( $self, $source, $records ) = @_;

    my $rs = $source->resultset;
    $self->log->debug("populate records");

    my $count      = 0;
    my $block_size = $LOAD_BLOCK_SIZE;
    my $offset     = 0;

    while ( $offset < @$records - 1 ) {
        my $last_record_index = $offset + $block_size - 1;
        $last_record_index > @$records - 1 and $last_record_index = @$records - 1;

        my $data = [ @$records[ $offset .. $last_record_index ] ];

        try {
            $self->log->debug( "populate $offset, $last_record_index - " . scalar(@$data) );
            $self->schema->txn_do(
                sub {
                    if ( $self->enable_fk ) {
                        $rs->populate($data);
                    }
                    else {
                        $self->schema->storage->with_deferred_fk_checks(
                            sub {
                                $rs->populate($data);
                            }
                        );
                    }
                }
            );
        }
        catch {
            if ( $self->force ) {
                $self->log->debug("Recovering from error: $_");
                $self->log->debug("Forcing populate offset=$offset");
                foreach my $row (@$data) {
                    try {
                        $self->schema->txn_do(
                            sub {
                                if ( $self->enable_fk ) {
                                    $rs->populate( [$row] );
                                }
                                else {
                                    $self->schema->storage->with_deferred_fk_checks(
                                        sub {
                                            $rs->populate( [$row] );
                                        }
                                    );
                                }
                            }
                        );
                    }
                    catch {
                        $count++;
                        $self->log->debug("Error while recovering: $_");
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

sub _update_records {
    my ( $self, $source, $records ) = @_;

    my $count = 0;

    my $rs = $source->resultset;
    $self->log->debug("update records");

    foreach my $row (@$records) {
        try {
            $rs->update_or_create($row);
        }
        catch {
            if ( $self->force ) {
                $count++;
                $self->log->warn("Error while updating: $_");
            }
            else {
                $self->log->logdie("Fatal error: $_");
            }
        };
    }

    $self->log->error("Warning: $count errors ignored!") if ($count);
    $self->log->info( scalar(@$records) - $count, " updated loaded in table " . $source->name );
}

=method load( )

Load data from C<$self->filename>.

=cut

sub load {
    my ($self) = @_;

    my $datadump = App::Manoc::DataDumper::Data->load( $self->filename );

    if ( !defined($datadump) ) {
        $self->log->fatal( "cannot open ", $self->filename );
        return;
    }

    my $source_names = $self->source_names;
    $self->log->debug( 'Sources: ', join( ',', @$source_names ) );

    $self->schema->storage->ensure_connected();
    $self->_load_sources($datadump);

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

    # trick to optimize array usage:
    # 1) set $#array=n to preallocate storage by creating an array of n
    # undef values
    # 2) clear the array in order to be able to use push as usual

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
