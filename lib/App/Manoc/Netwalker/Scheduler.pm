package App::Manoc::Netwalker::Scheduler;
use Moose;
use namespace::autoclean;

##VERSION
with 'App::Manoc::Logger::Role';

use Moose::Util::TypeConstraints;
use POE;

subtype 'ManagerType' => as 'Object' => where
    sub { $_->does('App::Manoc::Netwalker::WorkersRole') };

has config => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);

has workers_manager => (
    is      => 'ro',
    isa     => 'ArrayRef[ManagerType]',
    default => sub { [] },
    traits  => ['Array'],

    handles => {
        all_workers => 'elements',
        add_workers => 'push',
    },
);

has session => (
    isa      => 'POE::Session',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        POE::Session->create( object_states => [ $_[0] => [qw ( _start tick )] ] );
    }
);

has tick_interval => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
    default  => 60,
);

has schema => (
    is       => 'ro',
    required => 1
);

has next_alarm_time => (
    is  => 'rw',
    isa => 'Int',
);

sub _start {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    $self->log->debug( "starting scheduler, tick=", $self->tick_interval );

    foreach my $m ( @{ $self->workers_manager } ) {
        $m->on_tick($kernel);
    }

    $self->next_alarm_time( time() + 1 );
    $kernel->alarm( tick => $self->next_alarm_time );
}

sub tick {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    $self->log->debug("scheduler tick");
    foreach my $m ( @{ $self->workers_manager } ) {
        $m->on_tick($kernel);
    }
    $self->next_alarm_time( $self->next_alarm_time + $self->tick_interval );
    $kernel->alarm( tick => $self->next_alarm_time );
}

sub BUILD {
    shift->session();
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
