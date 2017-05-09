package App::Manoc::Netwalker::Script;
#ABSTRACT: Manoc Netwalker script runner

use Moose;

##VERSION

=head1 DESCRIPTION

This class is responsible for running the Netwalker daemon. It extends
L<App::Manoc::Script::Daemon> and sets up the pollers workers, the
scheduler and the control interface.

=head2 SYNOPSIS

  use App::Manoc::Netwalker::Script;

  my $app = App::Manoc::Netwalker::Script->new_with_options();
  $app->run();

=cut

extends 'App::Manoc::Script::Daemon';

use POE;

use App::Manoc::Netwalker::Config;
use App::Manoc::Netwalker::Control;
use App::Manoc::Netwalker::Scheduler;
use App::Manoc::Netwalker::Poller::Workers;
use App::Manoc::Netwalker::Discover::Workers;

=method main

The entry point for the script.

=cut

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

=head1 SEE ALSO

L<App::Manoc::Netwalker::Config>, L<App::Manoc::Netwalker::Control>, L<App::Manoc::Netwalker::Scheduler>, L<App::Manoc::Netwalker::Poller::Workers>, L<App::Manoc::Netwalker::Discover::Workers>

=cut

# Clean up the namespace.
no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
