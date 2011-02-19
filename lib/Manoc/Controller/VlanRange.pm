# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::VlanRange;
use Moose;
use namespace::autoclean;
use Manoc::Form::VlanRange;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::VlanRange - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect('/vlanrange/list');
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('vlanrange') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::VlanRange') );

}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) {

    # $id = primary key
    my ( $self, $c, $id ) = @_;

    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !$c->stash->{object} ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=head2 save

Handle create and edit resources

=cut

sub save : Private {
    my ( $self, $c ) = @_;
    my $item = $c->stash->{object} ||
        $c->stash->{resultset}->new_result( {} );

    $c->stash( default_backref => $c->uri_for('/vlanrange/list') );

    my $form = Manoc::Form::VlanRange->new( item => $item );
    $c->stash( form => $form, template => 'vlanrange/save.tt' );

    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened
    return unless $form->process( params => $c->req->params );

    my $action = $c->stash->{object} ? "edited" : "created";
    $c->flash( message => "Success! Vlan Range $action" );

    $c->detach('/follow_backref');
}

=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('save');
}

=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;
    my $range = $c->stash->{'object'};
    my $id    = $range->id;
    my $name  = $range->name;
    $c->stash( default_backref => $c->uri_for('/vlanrange/list') );

    if ( lc $c->req->method eq 'post' ) {
        my @rs = $c->model('ManocDB::Vlan')->search( 'vlan_range' => $id );
        if (@rs) {
            $c->flash( error_msg =>
                    "Impossible delete vlan range, there are vlans that belong to this vlan range!"
            );
            $c->detach('/follow_backref');
        }

        $range->delete;
        my $msg =
            'Success!!  Range' . $name . ' ( ' . $range->start . '-' . $range->end .
            ' ) successful deleted.';
        $c->flash( message => $msg );
        $c->detach('/follow_backref');
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

=head2 list

=cut

sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    my @vlan_ranges = $c->stash->{'resultset'}->search(
        {},
        {
            order_by => [ 'start', 'vlans.id' ],
            prefetch => 'vlans',
            join     => 'vlans',
        }
    );
    $c->stash( vlan_ranges => \@vlan_ranges );
    $c->stash( template    => 'vlanrange/list.tt' );
}

=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('save');
}

=head2 split

=cut

sub split : Chained('object') : PathPart('split') : Args(0) {
    my ( $self, $c ) = @_;
    my $id          = $c->req->param('id');
    my $name1       = $c->req->param('name1');
    my $name2       = $c->req->param('name2');
    my $split_point = $c->req->param('split_point');
    my ( %tmpl_param, $vlan_range, $done, $message, $error );

    $c->stash( default_backref => $c->uri_for('/vlanrange/list') );

    #Call the split vlan range subroutine
    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }

        ( $done, $message, $error ) = $self->process_split_vlanrange($c);
        if ($done) {
            $c->flash( message => $message );
            $c->detach('/follow_backref');
        }
    }

    #Set template parameters
    $tmpl_param{error_msg}   = $message;
    $tmpl_param{error}       = $error;
    $tmpl_param{name1}       = $name1;
    $tmpl_param{name2}       = $name2;
    $tmpl_param{split_point} = $split_point;
    $tmpl_param{template}    = 'vlanrange/split.tt';

    $c->stash(%tmpl_param);
}

sub process_split_vlanrange : Private {
    my ( $self, $c ) = @_;
    my $id          = $c->req->param('id');
    my $name1       = $c->req->param('name1');
    my $name2       = $c->req->param('name2');
    my $split_point = $c->req->param('split_point');
    my $error       = {};
    my ( $vlan_range1, $vlan_range2, @vlans, $res, $message );

    #Check names
    ( $res, $message ) = check_name( $c, undef, $name1 );
    $res or $error->{name1} = $message;

    ( $res, $message ) = check_name( $c, undef, $name2 );
    $res or $error->{name2} = $message;

    ( $name1 eq $name2 ) and
        $error->{name1} = "Vlan range names can't be the same";

    my $vlan_range = $c->stash->{'object'};

    #Check split point
    ( $split_point >= $vlan_range->start and $split_point < $vlan_range->end ) or
        $error->{split} = "Split point must be inside " . $vlan_range->name . " vlan range";

    scalar( keys(%$error) ) and return ( 0, undef, $error );

    #Update DB (with a transaction)
    $c->model('ManocDB')->txn_do(
        sub {
            $vlan_range1 = $c->stash->{'resultset'}->create(
                {
                    name  => $name1,
                    start => $vlan_range->start,
                    end   => $split_point
                }
                ) or
                return ( 0, "Impossible split Vlan" );
            $vlan_range2 = $c->stash->{'resultset'}->create(
                {
                    name  => $name2,
                    start => $split_point + 1,
                    end   => $vlan_range->end
                }
                ) or
                return ( 0, "Impossible split Vlan" );

            @vlans = $c->model('ManocDB::Vlan')->search( 'vlan_range' => $id );
            foreach (@vlans) {
                if ( $_->id >= $vlan_range->start and $_->id <= $split_point ) {
                    $_->vlan_range( $vlan_range1->id );
                }
                else {
                    $_->vlan_range( $vlan_range2->id );
                }
                $_->update;
            }

            $vlan_range->delete or return ( 0, "Impossible split Vlan" );
        }
    );

    if ($@) {
        my $commit_error = $@;
        return ( 0, "Commit error: $commit_error" );
    }

    return ( 1, "Done. Vlan Range Successful splitted." );
}

sub merge : Chained('object') : PathPart('merge') : Args(0) {
    my ( $self, $c ) = @_;
    my $id                = $c->req->param('id');
    my $sel_vlan_range_id = $c->req->param('sel_vlan_range_id');
    my $new_name          = $c->req->param('new_name');
    my ( %tmpl_param, $vlan_range, $done, $message, $error );
    $c->stash( default_backref => $c->uri_for('/vlanrange/list') );

    #Call the split vlan range subroutine
    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }

        ( $done, $message, $error ) = $self->process_merge_vlanrange($c);
        if ($done) {
            $c->flash( message => $message );
            $c->detach('/follow_backref');
        }

    }

    #Retrieve vlan range attributes
    $vlan_range = $c->stash->{'object'};

    my @neighs =
        $c->model('ManocDB::VlanRange')
        ->search( [ { end => $vlan_range->start - 1 }, { start => $vlan_range->end + 1 } ] );

    #Set template parameters
    $tmpl_param{error}          = $error;
    $tmpl_param{error_msg}      = $message;
    $tmpl_param{id}             = $id;
    $tmpl_param{neighs}         = \@neighs;
    $tmpl_param{sel_vlan_range} = $sel_vlan_range_id;
    $tmpl_param{new_name}       = $new_name;
    $tmpl_param{template}       = 'vlanrange/merge.tt';
    $c->stash(%tmpl_param);

}

sub process_merge_vlanrange : Private {

    my ( $self, $c ) = @_;
    my $id                = $c->req->param('id');
    my $sel_vlan_range_id = $c->req->param('sel_vlan_range_id');
    my $new_name          = $c->req->param('new_name');
    my ( $neigh, $new_vlan_range, @vlans, $res, $message, $error );
    my $vlan_range = $c->stash->{'object'};

    #Check new vlan range name
    ( $res, $message ) = check_name( $c, undef, $new_name );
    $res or ( $error->{name} = $message and return ( $res, undef, $error ) );

    #Check neighbour
    $neigh = $c->stash->{'resultset'}->find($sel_vlan_range_id);
    $neigh or return ( 0, "Invalid neighbour vlan range" );

    #Update DB (with a transaction)
    $c->model('ManocDB')->txn_do(
        sub {
            $new_vlan_range = $c->stash->{'resultset'}->create(
                {
                    name  => $new_name,
                    start => $vlan_range->start < $neigh->start ? $vlan_range->start :
                        $neigh->start,
                    end => $vlan_range->end > $neigh->end ? $vlan_range->end :
                        $neigh->end
                }
                ) or
                return ( 0, "Impossible merge Vlan" );

            @vlans =
                $c->model('ManocDB::Vlan')
                ->search( [ { 'vlan_range' => $id }, { 'vlan_range' => $sel_vlan_range_id } ] );
            foreach (@vlans) {
                $_->vlan_range( $new_vlan_range->id );
                $_->update;
            }

            $vlan_range->delete or return ( 0, "Impossible merge Vlan" );
            $neigh->delete      or return ( 0, "Impossible merge Vlan" );
        }
    );

    if ($@) {
        my $commit_error = $@;
        return ( 0, "Impossible update database: $commit_error" );
    }

    return ( 1, "Done. VlanRange successfull merged." );
}

sub check_name : Private {
    my ( $c, $id, $name ) = @_;

    my $dup = $c->stash->{'resultset'}->find( 'name' => $name );
    if ($dup) { $dup->id == $id or return ( 0, "Duplicated vlan range name" ); }
    $name =~ /^\w[\w-]*$/ or return ( 0, "Invalid vlan range name" );
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
