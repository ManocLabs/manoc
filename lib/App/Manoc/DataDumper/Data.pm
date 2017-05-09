package App::Manoc::DataDumper::Data;
#ABSTRACT: Class for managing datadumper file

use Moose;

##VERSION

=head1 DESCRIPTION

Use this class to create or load data dumper files. A data dumper file
is just a tar file containing a yaml files. Each yaml file contains a
set of records for a DB table.

=head1 SYNOPSIS

  $datadump = App::Manoc::DataDumper::Data->init( $filename, $version, $config );

  [...]
  foreach  $source ( @datasources ) {
    $table = $source->result_source->name;
    @data = $source->all;
    $datadump->add_file( "$table.yaml", \@data );
  }
  $datadump->save;

  my $datadump = App::Manoc::DataDumper::Data->load( $self->filename );
  my $version = $datadump->metadata->{'version'};

  my $records = $datadump->load_file("$table.yml");

=cut

use Archive::Tar;
use App::Manoc::Utils;
use YAML::Syck;
use File::Temp qw/tempdir/;
use File::Spec;
use Try::Tiny;

has 'filename' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has version => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
);

has 'config' => (
    is       => 'ro',
    required => 0,
);

has tar => (
    is       => 'rw',
    isa      => 'Archive::Tar',
    required => 0,
);

has filelist => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has metadata => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has tmpdir => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_metadata {
    my $self = shift;

    #we are in a save action
    if ( $self->version ) {
        return { version => $self->version };
    }

    #in the first version, the dumper dosen't create metadata file
    unless ( $self->tar->contains_file('_metadata') ) {
        return { version => 1 };
    }

    my $content = $self->tar->get_content('_metadata');
    return YAML::Syck::Load($content);
}

sub _build_tmpdir {
    return tempdir( "manocdumpXXXXXX", TMPDIR => 1, CLEANUP => 1 );
}

=method load( $filename )

Load a manoc dump file.

=cut

sub load {
    my ( $self, $filename ) = @_;

    my $tar;

    -f $filename or return;
    try {
        $tar = Archive::Tar->new($filename);
    };
    $tar or return;

    my $obj = $self->new(
        {
            filename => $filename,
            tar      => $tar
        }
    );
    $obj->filelist( [ grep( !/_metadata/, $obj->tar->list_files ) ] );
    return $obj;
}

=class_method load_file( $filename )

Open the yaml file C<$filename> from the manoc dump archive and return
a reference to the array of records found on it.

=cut

sub load_file {
    my ( $self, $filename ) = @_;

    my $content = $self->tar->get_content($filename);
    unless ($content) {
        # if the table has no records the YAML file is empty (and YAML doesn't love empty files)
        return 0;
    }
    my @data = YAML::Syck::Load($content);
    return \@data;
}

=class_method init( $filename, $version, $config )

Create a new dumper file.

=cut

sub init {
    my ( $self, $filename, $version, $config ) = @_;

    return $self->new(
        {
            filename => $filename,
            version  => $version,
            config   => $config,
        }
    );
}

=method add_file( $filename, $array_ref )

Add a C<$filename> file to the current dump serialing records form
C<$array_ref>.

=cut

sub add_file {
    my ( $self, $filename, $array_ref ) = @_;
    return unless ( defined($array_ref) and scalar( @{$array_ref} ) );

    # build filename inside tmpdir
    $filename = File::Spec->catfile( $self->tmpdir, $filename );

    my $fh;
    open $fh, ">", $filename;
    print $fh YAML::Syck::Dump( @{$array_ref} );

    #register filename in filelist
    push @{ $self->filelist }, $filename;

    #free resources
    close $fh;
}

=method save

Create dump file, i.e. a tar file containing all the serialized record
plus a metadata file.

=cut

sub save {
    my ($self) = @_;

    # before finalizing create the metadata inside the tar
    exists $self->metadata->{version} or die "Missing version in metadata";
    $self->add_file( "_metadata", [ $self->metadata ] );

    #finally create the file .tar.gz with file included in @filelist
    App::Manoc::Utils::tar( $self->filename, $self->tmpdir, $self->filelist );
}

no Moose;
# Clean up the namespace.
__PACKAGE__->meta->make_immutable();

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
