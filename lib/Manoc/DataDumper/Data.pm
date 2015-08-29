# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Data;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Moose;
use Archive::Tar;
use Manoc::Utils;
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
    return tempdir( "manocdumpXXXXXX", TMPDIR=>1, CLEANUP => 1 );
}

sub load {
    my ( $self, $filename ) = @_;

    my $tar;

    -f $filename or return undef;
    try {
       $tar = Archive::Tar->new($filename);
    };
    $tar or return undef;

    my $obj=  $self->new(
        {
            filename => $filename,
            tar      => $tar
        }
    );
    $obj->filelist([ grep(!/_metadata/, $obj->tar->list_files) ]);
    return $obj;
}

#returns a reference to the array of records loaded from the yaml file
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

sub add_file {
    my ( $self, $filename, $array_ref ) = @_;
    return unless(defined($array_ref) and scalar(@{$array_ref}));

    # build filename inside tmpdir
    $filename = File::Spec->catfile($self->tmpdir, $filename);

    my $fh;
    open $fh, ">", $filename;
    print $fh YAML::Syck::Dump( @{ $array_ref } );

    #register filename in filelist
    push @{$self->filelist}, $filename;

    #free resources
    close $fh;
}

sub save {
    my ($self) = @_;

    # before finalizing create the metadata inside the tar
    exists $self->metadata->{version} or die "Missing version in metadata";
    $self->add_file("_metadata", [$self->metadata]);

    #finally create the file .tar.gz with file included in @filelist
    Manoc::Utils::tar($self->filename, $self->tmpdir, $self->filelist);
}

no Moose;
# Clean up the namespace.
__PACKAGE__->meta->make_immutable();


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Manoc::DataDumper::Data - Represents a data file

=head1 AUTHORS

The Manoc Team

=head1 COPYRIGHT

This software is copyright (c) 2011-2015 by the Manoc Team

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=end

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
