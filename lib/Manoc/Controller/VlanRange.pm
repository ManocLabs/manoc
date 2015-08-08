# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::VlanRange;
use Moose;
use namespace::autoclean;


BEGIN { extends 'Catalyst::Controller'; }
with "Manoc::ControllerRole::CommonCRUD";
with "Manoc::ControllerRole::JSONView";

use Manoc::Form::VlanRange;
use Manoc::Form::VlanRange::Merge;
use Manoc::Form::VlanRange::Split;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vlanrange',
        }
    },
    class      => 'ManocDB::VlanRange',
);



=head1 NAME

Manoc::Controller::VlanRange - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 split

=cut

sub split : Chained('object') : PathPart('split') : Args(0) {
    my ( $self, $c ) = @_;

    my $form = Manoc::Form::VlanRange::Split->new();

    $c->stash(
        form   => $form,
        action => $c->uri_for($c->action, $c->req->captures),
    );
    return unless $form->process(
        item   =>  $c->stash->{object},
        params =>  $c->req->parameters,
    );

    $c->response->redirect(
	$c->uri_for_action( 'vlanrange/list' )
    );
    $c->detach();
}

sub merge : Chained('object') : PathPart('merge') : Args(0) {
    my ( $self, $c ) = @_;

    my $form = Manoc::Form::VlanRange::Merge->new();

    $c->stash(
        form   => $form,
        action => $c->uri_for($c->action, $c->req->captures),
    );
    return unless $form->process(
        item   =>  $c->stash->{object},
        params =>  $c->req->parameters,
    );

    $c->response->redirect(
        $c->uri_for_action( 'vlanrange/list' )
    );
    $c->detach();
}


=head1 METHODS

=cut

=head2 get_form

=cut

sub get_form {
    my ( $self, $c ) = @_;

    return Manoc::Form::VlanRange->new( );
}

=head2 delete_object

=cut

sub delete_object {
    
    my ( $self, $c ) = @_;
    my $range = $c->stash->{'object'};
    my $id    = $range->id;
    my $name  = $range->name;

    if ( $range->vlans->count() ) {
	$c->flash( error_msg =>
                    "There are vlans in vlan range '$name'. Cannot delete it."
		);
	return undef;
    }

    return $range->delete;
}

=head2 get_object_list

=cut

sub get_object_list {
    my ( $self, $c ) = @_;
    return [ $c->stash->{'resultset'}->search(
        {},
        {
            order_by => [ 'start', 'vlans.id' ],
            prefetch => 'vlans',
            join     => 'vlans',
        }
    )->all() ];
}


=head2 get_delete_failure_url

=cut


sub get_delete_failure_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action($c->namespace . "/list");
}

=head2 prepare_json_object

=cut

sub prepare_json_object  {
    my ($self, $range) = @_;
    return {
	id   => $range->name,
	name => $range->name,
	description => $range->description,
    };
};

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
