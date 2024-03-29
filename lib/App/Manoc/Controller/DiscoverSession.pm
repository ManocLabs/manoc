package App::Manoc::Controller::DiscoverSession;
#ABSTRACT: DiscoverSession - Catalyst Controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::DiscoverSession;

BEGIN { extends 'Catalyst::Controller'; }
with "App::Manoc::ControllerRole::CommonCRUD" => { -exclude => qw/update/ };

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'autodiscover',
        }
    },
    class               => 'ManocDB::DiscoverSession',
    form_class          => 'App::Manoc::Form::DiscoverSession',
    view_object_perm    => undef,
    object_list_options => {
        join      => 'discovered_hosts',
        distinct  => 1,
        '+select' => [ { count => 'discovered_hosts.id' } ],
        '+as'     => [qw/num_hosts/],
    }
);

=action get_object

=cut

sub get_object {
    my ( $self, $c, $pk ) = @_;
    return $c->stash->{resultset}->find(
        $pk,
        {
            join     => 'discovered_hosts',
            prefetch => 'discovered_hosts',
        }
    );
}

=action command

To be used via AJAX. Start, stop or delete a session.

=cut

sub command : Chained('base') : PathPart('command') : POST {
    my ( $self, $c ) = @_;

    my $id      = $c->request->body_parameters->{session};
    my $session = $self->get_object( $c, $id );
    if ( !$session ) {
        $c->detach('/error/http_404');
    }

    my $cmd = lc( $c->request->body_parameters->{command} );

    # check permissions
    $cmd =~ /^(restart|start|stop)$/ and
        $c->require_permission( $session, 'edit' );
    $cmd eq 'delete' and
        $c->require_permission( $session, 'delete' );

    my $result = {};
    if ( $cmd eq 'restart' ) {
        $session->restart();
        $session->update();
        $result->{status} = 'success';
    }
    elsif ( $cmd eq 'stop' ) {
        if ( $session->is_waiting || $session->is_running ) {
            $session->status( $session->STATUS_STOPPED );
            $session->update();
        }
        $result->{status} = 'success';
    }
    elsif ( $cmd eq 'start' ) {
        if ( $session->is_stopped ) {
            $session->status( $session->STATUS_WAITING );
            $session->update();
        }
        $result->{status} = 'success';
    }
    elsif ( $cmd eq 'delete' ) {
        $session->delete();
        $result->{status} = 'success';
    }
    else {
        $result->{status}  = 'error';
        $result->{message} = 'command not found';
    }

    $c->stash( json_data => $result );
    $c->forward('View::JSON');
}

=action get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    my $action = $c->namespace . "/list";
    return $c->uri_for_action($action);
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
