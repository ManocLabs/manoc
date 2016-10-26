package Manoc::Script;

# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

use Moose;
with 'MooseX::Getopt::Dashes';
with 'Manoc::Logger::Role';

use Config::JFDI;
use FindBin;
use File::Spec;

use Manoc::DB;
use Manoc::Logger;

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0
);

has 'debug' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0
);

has 'config' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_config'
);

has 'schema' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_schema'
);

sub _build_config {
    my $self = shift;
    my $config;

    if ( $ENV{MANOC_CONF} ) {
        $config = Config::JFDI->open( file => $ENV{MANOC_CONF}, );
    }
    else {
        my @config_paths =
            ( File::Spec->catdir( $FindBin::Bin, File::Spec->updir() ), '/etc', );

        foreach my $path (@config_paths) {
            $config = Config::JFDI->open(
                path => $path,
                name => 'manoc',
            );
            $config and last;
        }
    }
    if ( ! $config ) {
        $config = {
            name => 'Manoc',

            'Model::ManocDB' => {
                connect_info => {
                    dsn => $ENV{MANOC_DB_DSN} || 'dbi:SQLite:manoc.db',
                    user => $ENV{MANOC_DB_USERNAME} || undef,
                    password => $ENV{MANOC_DB_PASSWORD} || undef,
                    # dbi_attributes
                    quote_names => 1,
                    # extra attributes
                    AutoCommit  => 1,
                },
            },
        }
    }

    return $config;
}

sub _build_schema {
    my $self = shift;

    my $config       = $self->config;
    my $connect_info = $config->{'Model::ManocDB'}->{connect_info};
    my $schema       = Manoc::DB->connect($connect_info);

    return $schema;
}

sub _init_logging {
    my $self = shift;

    return if Manoc::Logger->initialized();

    my %args;
    $args{debug} = $self->debug;
    $args{class} = ref($self);

    Manoc::Logger->init( \%args );
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
