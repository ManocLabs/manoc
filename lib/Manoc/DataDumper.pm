package Manoc::DataDumper;
# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

use Moose;
use Manoc::DB;
use Manoc::DataDumper::Converter;
use Manoc::DataDumper::VersionType;

use DBIx::Class::ResultClass::HashRefInflator;

use Try::Tiny;

my $ROWS = 100000;
my $LOAD_BLOCK_SIZE = 1000;

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
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
);

has 'version' => (
    is        => 'rw',
    isa       => 'Version',
    lazy      => 1,
    builder   => '_build_version',
);


sub _build_version {
    my $self = shift;
    return Manoc::DB::get_version;
}

sub get_source_names {
    my $self = shift;

    my @include_list = @{ $self->include };
    @include_list = $self->schema->sources unless ( scalar(@include_list) );
    my @exclude_list = @{ $self->exclude };
    if ( scalar(@exclude_list) ) {
        my %filter = map { $_ => 1 } @exclude_list;
        @include_list = grep { !$filter{$_} } @include_list;
    }
    return \@include_list;
}

#----------------------------------------------------------------------#
#                      L O A D   A C T I O N                           #
#----------------------------------------------------------------------#


sub load_tables_loop {
    my ( $self, $source_names, $datadump, $file_set, $overwrite, $force ) = @_;
    my $converter;
    
    # try to load a converter if needed
    my $version = $datadump->metadata->{'version'};
    if ( $version < Manoc::DB::get_version ) {
        my $converter_class =
            Manoc::DataDumper::Converter->get_converter_class( $version );
        
        if (defined($converter_class) ) {
            $converter = $converter_class->new({ log => $self->log });
            $self->log->info("Using converter $converter_class.");
        }        
    }
    
    foreach my $source_name (@$source_names) {
        my $source = $self->schema->source($source_name);
        next unless $source->isa('DBIx::Class::ResultSource::Table');
        my $table = $source->from;

        if ($overwrite) {
            $self->log->debug("Cleaning $source_name");
            $source->resultset->delete();
        }
        
        my @filenames = grep(/^$table\./, keys %{$file_set});
        if (@filenames > 1 ) {
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
            my $count = scalar(@$records);
            
            $self->log->info("Read $count records from $filename");
            unless ($count) {
                $self->log->info("Skipped empy file $filename");
                next;
            }

            # convert records if needed
            $converter and $converter->upgrade_table( $records, $table );

            # load into db
            $self->load_table( $source, $records, $force );

            #free memory
            undef $records;
        }
    }
}

sub load_table {
    my ( $self, $source, $records, $force ) = @_;

    my $rs = $source->resultset;
    $self->log->debug("load table");

    my $count = 0;
    my $block_size = $LOAD_BLOCK_SIZE;
    my $offset = 0;

    while ($offset < @$records - 1) {
        my $last_record_index = $offset + $block_size - 1;
        $last_record_index > @$records - 1 and $last_record_index = @$records - 1;
        
        my $data = [ @$records[$offset, $last_record_index] ];
        
        try {
            $rs->populate( $data );       
        } catch {
            if ($force) {
                $self->log->debug("forcing populate offset=$offset");
                foreach my $row (@$data) {
                    try {
                        $rs->populate( [$row] );
                    } catch {
                        $count++;
                        $self->log->debug("Recovering error: $_");

                    };
                }
            } else {
                $self->log->logdie("Fatal error: $_");
            }
        };

        $offset += $block_size;
    }
    
    $self->log->error("Warning: $count errors ignored!") if ($count);
    $self->log->info( scalar(@$records) - $count, " records loaded in table " . $source->name );    
}

sub load {
    my ( $self, $disable_fk, $overwrite, $force ) = @_;

    my $datadump = Manoc::DataDumper::Data->load( $self->filename );

    if (! defined($datadump)) {
        $self->log->fatal("cannot open ", $self->filename);
        return undef;
    }
    
    #filter metadata file from sources 
    my $file_set = { map { $_ => 1 } grep(!/_metadata/, $datadump->tar->list_files) };
    my $source_names = $self->get_source_names();

    if ($disable_fk) {
        # force loading the correct storage backend before
        # calling with_deferred_fk_checks
        $self->schema->storage->ensure_connected();

        $self->schema->storage->with_deferred_fk_checks(
            sub {
                $self->load_tables_loop( $source_names, $datadump, $file_set, $overwrite,
                    $force );
            }
        );
    }
    else {
        $self->load_tables_loop( $source_names, $datadump, $file_set, $overwrite, $force );
    }
    $self->log->info("Database restored!");
}


#----------------------------------------------------------------------#
#                      S A V E   A C T I O N                           #
#----------------------------------------------------------------------#

sub save {
    my ($self) = @_;
    
    my $datadump = Manoc::DataDumper::Data->init(
        $self->filename,
        $self->version,
        $self->config->{DataDumper} );
    
    my $path_to_tar  = $self->config->{DataDumper}->{path_to_tar} || undef;    
    my $source_names = $self->get_source_names();
    
    foreach my $source_name (@$source_names) {
        my $source = $self->schema->resultset($source_name);
        next unless $source->isa('DBIx::Class::ResultSet');

        my $table = $source->result_source->name;
        
        $self->log->debug("Processing table $table");             
        $self->schema->storage->dbh_do(\&_dump_table, $self->log, $datadump, $source, $ROWS);
        $self->log->info("Table $table dumped");
    }
    
    $self->log->debug("Writing the archive...");
    defined($path_to_tar) and $self->log->debug("use system tar in $path_to_tar ");

    $datadump->save;
    $self->log->info("Database dumped.");

}


sub _dump_table {
    my ( $storage, $dbh, $log, $datadump, $source, $rows) = @_;
    my $table = $source->result_source->name;    

    my $n_entries = $source->count;   

    $source->result_class('DBIx::Class::ResultClass::HashRefInflator');   
    return unless $n_entries > 0;
  
    if ($n_entries <= $ROWS) {
        my @data = $source->all;
        my $filename = "$table.yaml";
        $datadump->add_file($filename, \@data);
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
    @data = ();    
    my $rs = $source->search();
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');   

    while (my $entry = $rs->next) {
        push @data, $entry;

        if (@data == $ROWS) {
            my $filename = "$table.$page.yaml";
            $datadump->add_file($filename, \@data);
            $log->debug("saved $filename");
            @data = ();
            $page++;
        }
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
