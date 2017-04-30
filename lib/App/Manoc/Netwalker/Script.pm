package App::Manoc::Netwalker::Script;

use Moose;

##VERSION

extends 'App::Manoc::Script::Daemon';

use POE;

use App::Manoc::Netwalker::Config;
use App::Manoc::Netwalker::Control;
use App::Manoc::Netwalker::Scheduler;
use App::Manoc::Netwalker::Poller::Workers;
use App::Manoc::Netwalker::Discover::Workers;

sub main {
    my $self = shift;

    $ENV{LANG} = 'C';

    $self->log->info("Starting netwalker");

    # get configuration and store it in a Config object
    my %config_args = %{ $self->config->{Netwalker} || {} };
    $config_args{manoc_config_dir} ||= $self->manoc_config_dir;

    my $config = App::Manoc::Netwalker::Config->new(%config_args);

    my $poller_workers = App::Manoc::Netwalker::Poller::Workers->new(
        config => $config,
        schema => $self->schema,
    );

    my $discover_workers = App::Manoc::Netwalker::Discover::Workers->new(
        config => $config,
        schema => $self->schema,
    );

    my $scheduler = App::Manoc::Netwalker::Scheduler->new(
        config => $config,
        schema => $self->schema,
    );
    $scheduler->add_workers($poller_workers);
    $scheduler->add_workers($discover_workers);

    my $control = App::Manoc::Netwalker::Control->new(
        config     => $config,
        poller     => $poller_workers,
        discoverer => $discover_workers,
    );

    POE::Kernel->run();
}

# Clean up the namespace.
no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
