package Manoc::DataDumper;

# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

use Moose;
use Manoc::DB;
use Manoc::DataDumper::Converter;
use Manoc::DataDumper::VersionType;
use Data::Dumper;

use Try::Tiny;

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
    builder   => '_build_dbversion',
);

has 'db_version' => (
    is        => 'rw',
    required  => 0,
);

sub _build_dbversion {
    my $self = shift;
    $self->db_version and return $self->db_version;
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
        my $c = 0;
        my $converter_class =
          Manoc::DataDumper::Converter->get_converter_class( Manoc::DB::get_version );
        
        if (defined($converter_class) ) {
            $converter = $converter_class->new({ log => $self->log });
            $self->log->info("Using converter $converter_class.");
        }        
    }

     foreach my $source_name (@$source_names) {
         my $source = $self->schema->source($source_name);
         next unless $source->isa('DBIx::Class::ResultSource::Table');

         my $table    = $source->from;
         my $filename = "$table.yaml";

         $file_set->{$filename} or next;

         $self->log->debug("Trying $filename");

         #load in RAM all the table records
         my $count = $datadump->load_data($table);

         unless ($count) {
             $self->log->info("File is empty. Skipping...");
             next;
         }
        
         $self->log->info("Loaded $count records from $table.yaml");

         if ( ! defined($datadump->data->{$table}) ) {
             $self->log->info("No data to import in $table");
             next;
         }
         #convert them if needed
         $converter and $converter->upgrade_table( $datadump->data, $table );
         #commit to backend
         $self->load_table( $source, $datadump->data->{$table}, $overwrite, $force );
         #free memory
         undef $datadump->data->{$table};
     }
}

sub load_table {
    my ( $self, $source, $data, $overwrite, $force ) = @_;

    my $rs = $source->resultset;

    $overwrite and $rs->delete();
    my $count = 0;
    if ($force) {
        foreach my $row (@$data) {
            try {
                $rs->populate( [$row] );
            }
            catch {
                $count++;
            }
        }
    }
    else {
        $rs->populate( [@$data] );
    }
    $self->log->error("Warning: $count errors ignored!") if ($count);
    $self->log->info( scalar(@$data), " records loaded in table " . $source->name );
    #free the memory!!
    $data = undef;
    
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



sub dump_table {
    my ( $storage, $dbh, $datadump, $table, $cols, $dir ) = @_;

    my $sth;

#    $sth = $dbh->prepare("SELECT count(*) FROM $table");
#    $sth->execute;
#    my $count = $sth->fetch->[0];
#    $sth->finish;

    my $cols_list = join( ",", @$cols );
    $sth = $dbh->prepare("SELECT $cols_list FROM $table") or die $dbh->errstr;
    $sth->execute or die $dbh->errstr;

    my @list;
    while ( my $hash_ref = $sth->fetchrow_hashref ) {
        push @list, $hash_ref;
    }
    $sth->finish;
    $datadump->save_table( "$table.yaml", \@list, $dir);
}

#----------------------------------------------------------------------#
#                      S A V E   A C T I O N                           #
#----------------------------------------------------------------------#

sub save {
    my ($self) = @_;
    
    my $datadump = Manoc::DataDumper::Data->save( $self->filename, $self->version , $self->config->{DataDumper} );
    my $path_to_tar = $self->config->{DataDumper}->{path_to_tar} || undef;
    my $dir         = $self->config->{DataDumper}->{directory} || undef;

    my $source_names = $self->get_source_names();

    foreach my $source_name (@$source_names) {
        my $source = $self->schema->source($source_name);
        next unless $source->isa('DBIx::Class::ResultSource::Table');

        my $table        = $source->from;
        my @column_names = $source->columns;

        $self->schema->storage->dbh_do( \&dump_table, $datadump, $table, \@column_names, $dir );
        $self->log->debug("Table $table writed in archive");


    }
    $self->log->debug("Writing the archive...");
    defined($path_to_tar) and $self->log->debug("...if available will be used system tar located in $path_to_tar ");

    $datadump->finalize_tar;
    $self->log->info("Database dumped!");

}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
