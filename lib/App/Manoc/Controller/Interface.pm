package App::Manoc::Controller::Interface;
#ABSTRACT: Interface Controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::IfNotes;

BEGIN { extends 'Catalyst::Controller'; }

=method base

=cut

sub base : Chained('/') : PathPart('interface') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::IfStatus') );
}

=method object

=cut

sub object : Chained('base') : PathPart('') : CaptureArgs(2) {
    my ( $self, $c, $device_id, $iface ) = @_;

    my $object_pk = {
        device_id => $device_id,
        interface => $iface,
    };

    $c->stash( object => $c->stash->{resultset}->find($object_pk) );
    if ( !$c->stash->{object} ) {
        $c->detach('/error/http_404');
    }

    $c->stash( object_pk => $object_pk );
}

=method view

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $object    = $c->stash->{'object'};
    my $object_pk = $c->stash->{object_pk};

    my $device = $c->model('ManocDB::Device')->find( { id => $object_pk->{device_id} } );
    $c->stash( device => $device );

    my $note = $c->model('ManocDB::IfNotes')->find($object_pk);
    $c->stash( notes => defined($note) ? $note->notes : '' );

    #MAT related results
    my @mat_rs = $c->model('ManocDB::Mat')
        ->search( $object_pk, { order_by => { -desc => [ 'lastseen', 'firstseen' ] } } );
    my @mat_results = map +{
        macaddr   => $_->macaddr,
        vlan      => $_->vlan,
        firstseen => $_->firstseen,
        lastseen  => $_->lastseen
    }, @mat_rs;

    $c->stash( mat_history => \@mat_results );
}

=method edit_notes

=cut

sub edit_notes : Chained('object') : PathPart('edit_notes') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $object_pk = $c->stash->{object_pk};

    my $ifnotes = $c->model('ManocDB::IfNotes')->find($object_pk);
    $ifnotes or $ifnotes = $c->model('ManocDB::IfNotes')->new_result( {} );

    my $form = App::Manoc::Form::IfNotes->new( { %$object_pk, ctx => $c } );
    $c->stash( form => $form );
    return unless $form->process(
        params => $c->req->params,
        item   => $ifnotes
    );

    my $dest_url =
        $c->uri_for_action( 'interface/view', [ @$object_pk{ 'device', 'interface' } ] );
    $c->res->redirect($dest_url);
}

=method delete_notes

=cut

sub delete_notes : Chained('object') : PathPart('delete_notes') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'delete' );

    my $object_pk = $c->stash->{object_pk};

    my $dest_url =
        $c->uri_for_action( 'interface/view', [ @$object_pk{ 'device', 'interface' } ] );

    my $item = $c->model('ManocDB::IfNotes')->find($object_pk);
    if ( !$item ) {
        $c->detach('/error/http_404');
    }

    if ( $c->req->method eq 'POST' ) {
        $item->delete;
        $c->res->redirect($dest_url);
        $c->detach();
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
