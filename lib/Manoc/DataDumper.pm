package Manoc::DataDumper;

# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

use FindBin;
use lib "$FindBin::Bin/../lib";

use Moose;
use Manoc::DataDumper::Converter;
use Manoc::DataDumper::VersionType;
use Data::Dumper;

has 'filename' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
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

has 'version' => (
    is      => 'rw',
    isa     => 'Version',
    default => '2.000000',
);

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

################################################################################################################
###################################### L O A D   A C T I O N ###################################################
################################################################################################################

sub load_tables_loop {
    my ( $self, $source_names, $datadump, $file_set, $overwrite, $force ) = @_;
    foreach my $source_name (@$source_names) {
        my $source = $self->schema->source($source_name);
        next unless $source->isa('DBIx::Class::ResultSource::Table');

        my $table    = $source->from;
        my $filename = "$table.yaml";

        $file_set->{$filename} or next;

        $self->log->debug("Trying $filename");
        my $count = $datadump->load_data($table);

        unless ($count) {
            $self->log->info("File is empty. Skipping...");
            next;
        }

        #convert data if needed
        if ( $datadump->metadata->{'version'} < Manoc::DB::get_version ) {
            my $c = 0;
            my $converter =
                Manoc::DataDumper::Converter->get_converter( $datadump->metadata->{'version'} );
            defined($converter) and $c = $converter->upgrade( $datadump->data, $table );
            $self->log->info("Number of records converted: $c");
        }

        $self->log->info("Loaded $count records from $table.yaml");
        $self->load_table( $source, $datadump->data->{$table}, $overwrite, $force );
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
}

sub load {
    my ( $self, $disable_fk, $overwrite, $force ) = @_;

    my $datadump = Manoc::DataDumper::Data->load( $self->filename );

    my $file_set = { map { $_ => 1 } $datadump->tar->list_files };
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

################################################################################################################
###################################### S A V E   A C T I O N ###################################################
################################################################################################################

sub dump_table {
    my ( $storage, $dbh, $datadump, $table, $cols ) = @_;

    my $sth;

    $sth = $dbh->prepare("SELECT count(*) FROM $table");
    $sth->execute;

    my $count = $sth->fetch->[0];
    $sth->finish;

    my $cols_list = join( ",", @$cols );
    $sth = $dbh->prepare("SELECT $cols_list FROM $table") or die $dbh->errstr;
    $sth->execute or die $dbh->errstr;

    my @list;
    while ( my $hash_ref = $sth->fetchrow_hashref ) {
        push @list, $hash_ref;
    }
    $sth->finish;

    $datadump->save_table( $table, \@list );
}

sub save {
    my ($self) = @_;

    my $datadump = Manoc::DataDumper::Data->save( $self->filename, $self->version );

    my $source_names = $self->get_source_names();

    foreach my $source_name (@$source_names) {
        my $source = $self->schema->source($source_name);
        next unless $source->isa('DBIx::Class::ResultSource::Table');

        my $table        = $source->from;
        my @column_names = $source->columns;

        $self->schema->storage->dbh_do( \&dump_table, $datadump, $table, \@column_names );
        $self->log->debug("Data loaded from $table");

    }
    $self->log->debug("Begin writing the archive");
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
