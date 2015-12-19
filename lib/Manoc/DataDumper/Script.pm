# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DataDumper::Script;
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Moose;

use Manoc::Support;
use Manoc::DataDumper;
use Manoc::DataDumper::Data;
use Manoc::Logger;

use File::Temp;
use File::Spec;

use Archive::Tar;
use Try::Tiny;

use YAML::Syck;

extends 'Manoc::Script';

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

has 'skip_notempty' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'load' => (
    is  => 'rw',
    isa => 'Str',
);

has 'save' => (
    is  => 'rw',
    isa => 'Str',
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

sub run_save {
    my ($self) = @_;

    $self->log->info("Beginning dump of database");

    my $datadumper = Manoc::DataDumper->new(
        {
            filename => $self->save,
            schema   => $self->schema,
            log      => $self->log,
            include  => $self->include,
            exclude  => $self->exclude,
            config   => $self->config,
        }
    );

    $datadumper->save;
}

######################################################################################

sub run_load {
    my $self = shift;

    $self->log->info('Beginning database restore...');

    my $datadumper = Manoc::DataDumper->new(
        {
            filename      => $self->load,
            schema        => $self->schema,
            log           => $self->log,
            include       => $self->include,
            exclude       => $self->exclude,
            config        => $self->config,
            skip_notempty => $self->skip_notempty,
        }
    );

    $datadumper->load( $self->enable_fk, $self->overwrite, $self->force );
}

########################################################################

sub run {
    my $self = shift;

    $self->load and return $self->run_load( $ARGV[1] );
    $self->save and return $self->run_save( $ARGV[1] );

    print STDERR "You must specify --load or --save\n";
    print STDERR $self->usage;
    exit 1;
}

no Moose;
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
