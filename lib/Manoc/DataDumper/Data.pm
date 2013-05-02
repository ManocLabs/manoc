# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Data;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Moose;
use Archive::Tar;
use YAML::Syck;
use Data::Dumper;
use File::Spec;
use Moose::Util::TypeConstraints;

use Manoc::DataDumper;
use Manoc::DataDumper::Converter;
use Manoc::DataDumper::VersionType;

use Manoc::DB;

use Try::Tiny;

has 'filename' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has version => (
    is       => 'ro',
    isa      => 'Version',
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

has data => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
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

sub _build_metadata {
    my $self = shift;

    if ( $self->version ) {
        #we are in a save action
        return { version => $self->version };
    }

    #in the first version, the dumper dosen't create metadata file
    unless ( $self->tar->contains_file('_metadata') ) {
        return { version => '1.000000' };
    }

    my $content = $self->tar->get_content('_metadata');
    return YAML::Syck::Load($content);
}

sub load {
    my ( $self, $filename ) = @_;

    my $tar;

    -f $filename or return undef;
    try {
       $tar = Archive::Tar->new($filename);
    }
    $tar or return undef;    
    
    return $self->new(
        {
            filename => $filename,
            tar      => $tar
        }
    );
}

#returns the number of records loaded from the yaml file
sub load_data {
    my ( $self, $table ) = @_;

    my $filename = "$table.yaml";

    my $content = $self->tar->get_content($filename);
    unless ($content) {
        # if the table have 0 records the YAML file is empty (and YAML doesn't love empty files)
        return 0;
    }
    my @data = YAML::Syck::Load($content);
    $self->data->{$table} = \@data;
    return scalar(@data);
}

sub save {
    my ( $self, $filename, $version, $config ) = @_;

    return $self->new(
        {
            filename => $filename,
            version  => $version,
            config   => $config,
        }
    );

}

sub save_table {
    my ( $self, $filename, $array_ref, $dir ) = @_;
    my $fh;
    
    defined($dir) or $dir = "/tmp";
    return unless(defined($array_ref) and scalar(@{$array_ref}));
    
    $filename = "$dir/$filename";
    die "Error! Directory $dir not exists" unless(-e $dir);
    open $fh, ">", $filename;
    print $fh YAML::Syck::Dump( @{ $array_ref } );

    #register filename in filelist
    push @{$self->filelist}, $filename;
    #free resources
    close $fh;
    undef $array_ref;
}

sub finalize_tar {
    my ($self) = @_;
    #before finalize we must create the metadata inside the tar
    exists $self->metadata->{version} or die "Missing version in metadata";
    my $dir = defined($self->config) ? $self->config->{directory} : undef;
    $self->save_table("_metadata", [$self->metadata],$dir);

    #finally create the file .tar.gz with file included in @filelist
    Manoc::Utils::tar( $self->config, $self->filename, @{$self->filelist});
}

no Moose;
# Clean up the namespace.
__PACKAGE__->meta->make_immutable();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
