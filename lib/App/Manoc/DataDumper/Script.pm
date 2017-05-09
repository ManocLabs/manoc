package App::Manoc::DataDumper::Script;
#ABSTRACT: Manoc Netwalker script runner

=head1 DESCRIPTION

This class is responsible for running the manoc dumper scripst. It extends
L<App::Manoc::Script> and can operate in two modes: load or save.

=cut

use Moose;

##VERSION

extends 'App::Manoc::Script';

use App::Manoc::Support;
use App::Manoc::DataDumper;
use App::Manoc::DataDumper::Data;
use App::Manoc::Logger;

use File::Temp;
use File::Spec;

use Archive::Tar;
use Try::Tiny;

use YAML::Syck;

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

=method run_save

Implements the save command to dump database to a datadumper file.

=cut

sub run_save {
    my ($self) = @_;

    $self->log->info("Beginning dump of database");

    my $datadumper = App::Manoc::DataDumper->new(
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

=method run_load

Implements the load command to restore database from a datadumper file.

=cut

sub run_load {
    my $self = shift;

    $self->log->info('Beginning database restore...');

    my $datadumper = App::Manoc::DataDumper->new(
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

=method run

The script entry point.

=cut

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
