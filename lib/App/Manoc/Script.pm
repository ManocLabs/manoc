package App::Manoc::Script;
use Moose;

##VERSION

with 'MooseX::Getopt::Dashes';
with 'App::Manoc::Logger::Role';

use Config::ZOMG;
use Cwd;
use FindBin;
use File::Spec::Functions;
use App::Manoc::DB;
use App::Manoc::Logger;

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

has 'manoc_config_dir' => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    default => sub { catdir( $FindBin::Bin, updir() ) }
);

sub _build_config {
    my $self = shift;
    my $config;

    if ( $ENV{MANOC_CONF} ) {
        $config = Config::ZOMG->open( file => $ENV{MANOC_CONF}, );
        my $path = catdir( $ENV{MANOC_CONF}, updir() );
        $self->manoc_config_dir($path);
    }
    else {
        my @config_paths = ( catdir( $FindBin::Bin, updir() ), '/etc/manoc', );

        foreach my $path (@config_paths) {
            $config = Config::ZOMG->open(
                path => $path,
                name => 'manoc',
            );
            if ($config) {
                $self->manoc_config_dir($path);
                last;
            }
        }
    }
    if ( !$config ) {
        $config = {
            name             => 'Manoc',
            'Model::ManocDB' => $App::Manoc::DB::DEFAULT_CONFIG,
        };
        $self->manoc_config_dir( getcwd() );
    }

    return $config;
}

sub _build_schema {
    my $self = shift;

    my $config       = $self->config;
    my $connect_info = $config->{'Model::ManocDB'}->{connect_info};

    my $schema = App::Manoc::DB->connect($connect_info);

    return $schema;
}

sub _init_logging {
    my $self = shift;

    return if App::Manoc::Logger->initialized();

    my %args;
    $args{debug} = $self->debug;
    $args{class} = ref($self);

    App::Manoc::Logger->init( \%args );
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
