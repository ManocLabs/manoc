package App::Manoc::Logger;
##ABSTRACT: A tiny wrapper around Log4perl

use strict;
use warnings;

##VERSION

use Carp;

use FindBin;
use Log::Log4perl;
use Log::Log4perl::Level;

=function initialized

Return true if the logger has been initialized.

=cut

sub initialized { Log::Log4perl->initialized(); }

=method logger

Return a Log4Perl logger.

=cut

sub logger {
    my $self = shift;
    Log::Log4perl->get_logger(@_);
}

sub _init_screen_logger {
    my ($category) = @_;
    my $logger = Log::Log4perl->get_logger($category);

    my $appender =
        Log::Log4perl::Appender->new( "Log::Log4perl::Appender::Screen", name => 'screenlog' );

    my $layout = Log::Log4perl::Layout::PatternLayout->new("[%d] %p %m%n");
    $appender->layout($layout);
    $logger->add_appender($appender);
    $logger->level($DEBUG);
}

=method init

Initialize Manoc loggers.

=cut

sub init {
    my $self  = shift;
    my %args  = ( scalar(@_) == 1 ) ? %{ $_[0] } : @_;
    my $class = $args{class} || '';

    return if Log::Log4perl->initialized();

    if ( $ENV{MANOC_SUPPRESS_LOG} ) {
        Log::Log4perl->easy_init($OFF);
        return;
    }

    if ( $args{debug} ) {
        _init_screen_logger('');
        return;
    }

    my $config_file = $ENV{MANOC_LOGCONFIG};
    unless ( defined($config_file) && -f $config_file ) {

        my @config_paths;
        exists $ENV{MANOC_CONFIG} and
            push @config_paths, $ENV{MANOC_CONFIG};
        push @config_paths, File::Spec->catdir( $FindBin::Bin, File::Spec->updir() );
        -d '/etc' and push @config_paths, '/etc';

        foreach my $p (@config_paths) {
            my $file = File::Spec->catfile( $p, 'manoc_log.conf' );
            -f $file or next;
            $config_file = $file;
            last;
        }
    }

    if ( defined($config_file) ) {
        -f $config_file or croak "Cannot open config file $config_file";
        Log::Log4perl->init($config_file);
    }
    else {
        _init_screen_logger('');
    }
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
