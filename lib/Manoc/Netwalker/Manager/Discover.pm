# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Manager::Discover;
use Moose;
use namespace::autoclean;

with 'Manoc::Netwalker::Manager';
with 'Manoc::Logger::Role';

use Manoc::Netwalker::DiscoverTask;

use Try::Tiny;
use POE qw(Filter::Reference Filter::Line);

use aliased 'Manoc::DB::Result::DiscoverSession';

has config => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Config',
    required => 1
);

has schema => (
    is       => 'ro',
    required => 1
);

has scoreboard => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has current_session => (
    is  => 'rw',
    isa => 'Maybe[Object]'
);

sub BUILD {

    my $self = shift;

    $self->schema->resultset('DiscoverSession')
        ->search( { status => DiscoverSession->STATUS_RUNNING } )
        ->update( { status => DiscoverSession->STATUS_WAITING } );
}

=head2 on_tick

Called by scheduler

=cut

sub on_tick {
    my $self = shift;

    $self->schedule_hosts;
}

# select a new session to be processed
sub schedule_session {
    my $self = shift;

    if ( $self->current_session && !$self->current_session->is_done ) {
        return;
    }

    my $rs      = $self->schema->resultset('DiscoverSession');
    my $session = $rs->search(
        {
            status =>
                { -in => [ DiscoverSession->STATUS_WAITING, DiscoverSession->STATUS_NEW, ] }
        }
    )->first();

    $self->current_session($session);
    return unless $session;

    $self->log->debug( "found waiting discover session " . $session->id );
    $session->status( DiscoverSession->STATUS_RUNNING );
    $session->update;
}

sub schedule_hosts {
    my $self = shift;

    $self->current_session or $self->schedule_session;
    $self->current_session or return;

    my $session = $self->current_session;

    my $curr_addr = $session->next_addr;
    my $to_addr   = $session->to_addr;

    $curr_addr ||= $session->from_addr;

    while ( $curr_addr <= $to_addr ) {

        if ( $self->check_worker_threshold ) {
            $self->log->debug("queue is full, stop scheduling addresses");
            last;
        }

        $self->scoreboard->{$curr_addr} = 'QUEUED';
        $self->enqueue( sub { $self->discover_address( $session->id, $curr_addr ) } );
        $self->log->debug("enqueued address $curr_addr");

        $curr_addr = Manoc::IPAddress::IPv4->new( { numeric => $curr_addr->numeric + 1 } );
    }

    $session->next_addr($curr_addr);
    if ( $curr_addr > $to_addr ) {
        $session->status( $session->STATUS_DONE );
        $self->current_session(undef);
    }

    $session->update();
}

sub worker_done {
    my $self = shift;

    my $session = $self->current_session;
    return unless $session;
    $session->discard_changes;

    if ( $session->is_running ) {
        $self->schedule_hosts;
    }
    else {
        $self->log->debug("session has been stopped");
        $self->current_session(undef);
    }
}

sub discover_address {
    my ( $self, $session_id, $address ) = @_;

    my $updater = Manoc::Netwalker::DiscoverTask->new(
        {
            schema     => $self->schema,
            config     => $self->config,
            session_id => $session_id,
            address    => $address,
        }
    );
    try {
        $self->log->debug("running scanner for $address");
        $updater->scan();
    }
    catch {
        $self->log->debug("Got error $_ while scanning $address");
    };

}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
