# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Vlan;
use Moose;
use namespace::autoclean;
use Manoc::Form::Vlan;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Vlan - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect('/vlan/list');
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('vlan') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::Vlan') );
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

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $id = $c->stash->{'object'}->id;

    my @ranges = $c->model('ManocDB::IPRange')->search( { 'vlan_id' => $id } );

    my $vlan_range = $c->model('ManocDB::VlanRange')->find(
        {
            start => { '<=' => $id },
            end   => { '>=' => $id }
        }
    );

    #Set template parameters
    $c->stash( template => 'vlan/view.tt', ranges => \@ranges );

    my @rs = $c->model('ManocDB::IfStatus')->search(
        { 'me.vlan' => $id, },
        {
            alias => 'me',
            from  => [
                { me => 'if_status' },
                [
                    { 'dev_entry'    => 'devices', -join_type => 'LEFT' },
                    { 'dev_entry.id' => 'me.device', }
                ]
            ],
            group_by => [qw(me.device)],
            select =>
                [ 'me.device', 'dev_entry.name', { count => { distinct => 'me.interface' } }, ],
            as => [qw(device name count)]
        }
    );

    my @devices = map {
        device    => $_->device,
            name  => $_->get_column('name'),
            count => $_->get_column('count'),
    }, @rs;

    $c->stash( devices => \@devices );

}

=head2 list

=cut

sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema    = $c->stash->{resultset};
    my $condition = {};

    my @vlan_vtp = $c->model('ManocDB::VlanVtp')->search();
    my %vtp_name;
    foreach my $vtp (@vlan_vtp) {
        $vtp_name{ $vtp->id } = {
            name    => $vtp->name,
            visited => 0,
        };
    }

    my @vlan_db = $schema->search();
    my @vlan_list;
    foreach (@vlan_db) {
        push @vlan_list,
            {
            id          => $_->id,
            name        => $_->name,
            name_vtp    => $vtp_name{ $_->id }->{'name'},
            vlan_range  => $_->vlan_range,
            description => $_->description
            };
        $vtp_name{ $_->id }->{'visited'} = 1;
    }

    my @vlan_outdb;
    foreach ( keys %vtp_name ) {
        unless ( $vtp_name{$_}->{'visited'} ) {
            push @vlan_outdb,
                {
                id         => $_,
                name       => $vtp_name{$_}->{'name'},
                vlan_range => $c->model('ManocDB::VlanRange')->find(
                    {
                        start => { '<=' => $_ },
                        end   => { '>=' => $_ }
                    }
                ),
                };
        }
    }

    $c->stash(
        vlan_list => \@vlan_list,
        vlan_vtp  => \@vlan_outdb,
        template  => 'vlan/list.tt'
    );
}

=head2 merge_name

=cut

sub merge_name : Chained('object') : PathPart('merge_name') : Args(0) {
    my ( $self, $c ) = @_;
    my $name = $c->req->param('new_name');
    $c->stash( error_msg => 'Vlan name not defined!' ) unless ($name);
    $c->stash->{'object'}->update( { name => $name } ) if ($name);
    $c->response->redirect( $c->uri_for('/vlan/list') );
    $c->detach();
}

=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;
    my ( %tmpl_param, $done, $message, $error );
    $c->stash( default_backref => $c->uri_for('/vlan/list') );

    #Call the new vlan subroutine
    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->stash( default_backref => $c->uri_for('/vlanrange/list') );
            $c->detach('/follow_backref');
        }

        ( $done, $message, $error ) = $self->process_new_vlan($c);
        if ($done) {
            $c->flash( message => $message );
            $c->detach('/follow_backref');
        }
    }

    #Set template parameters
    $tmpl_param{error}           = $error;
    $tmpl_param{error_msg}       = $message;
    $tmpl_param{template}        = 'vlan/create.tt';
    $tmpl_param{id}              = $c->req->param('id');
    $tmpl_param{vlan_name}       = $c->req->param('name');
    $tmpl_param{description}     = $c->req->param('description');
    $tmpl_param{forced_range_id} = $c->req->param('forced_range_id');
    $c->stash(%tmpl_param);
}

sub process_new_vlan : Private {
    my ( $self, $c ) = @_;
    my $id              = $c->request->body_parameters->{'id'};
    my $name            = $c->request->body_parameters->{'name'};
    my $description     = $c->request->body_parameters->{'description'};
    my $forced_range_id = $c->request->body_parameters->{'forced_range_id'};
    my ( $vlan_range, $res, $message );
    my $error = {};

    #Check new vlan id
    $id =~ /^\d+$/ or $error->{id} = "Invalid vlan id";
    $c->model('ManocDB::Vlan')->find( 'id' => $id ) and
        $error->{id} = "Duplicated vlan id";

    #Check parameters
    my $dup = $c->stash->{'resultset'}->find( 'name' => $name );
    $dup and $error->{name} = "Duplicated vlan name";
    $name =~ /^\w[\w-]*$/ or $error->{name} = "Invalid vlan name";

    scalar( keys(%$error) ) and return ( 0, undef, $error );

    #Get and check vlan range
    $vlan_range = $c->model('ManocDB::VlanRange')->find(
        {
            start => { '<=' => $id },
            end   => { '>=' => $id }
        }
    );
    $vlan_range or
        return ( 0, "You have to create the vlan inside a vlan range" );
    if ($forced_range_id) {
        if ( $vlan_range->id != $forced_range_id ) {
            my $forced_range =
                $c->model('ManocDB::VlanRange')->find( { 'id' => $forced_range_id } );
            $forced_range and return ( 0, "Forced range id found" );
            return ( 0,
                "You have to create a vlan inside vlan range: " . $forced_range->name . " (" .
                    $forced_range->start . " - " . $forced_range->end . ")" );
        }
    }
    $c->stash->{'resultset'}->create(
        {
            id          => $id,
            name        => $name,
            description => $description,
            vlan_range  => $vlan_range->id
        }
        ) or
        return ( 0, "Impossible create Vlan" );
    return ( 1, "Success Vlan $id ($name) successful created!" );
}

=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{'object'};
    my $form = Manoc::Form::Vlan->new( item => $item );
    $c->stash( default_backref => $c->uri_for('/rack/list') );

    $c->stash( form => $form, template => 'vlan/edit.tt' );

    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }

    return unless $form->process( params => $c->req->params );

    $c->flash( message => 'Success! Vlan Edited.' );
    $c->stash( default_backref => $c->uri_for_action( '/vlan/view', [ $item->id ] ) );
    $c->detach('/follow_backref');
}

=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;
    my $vlan = $c->stash->{'object'};

    if ( lc $c->req->method eq 'post' ) {
        my @range = $c->model('ManocDB::IPRange')->search( 'vlan_id' => $vlan->id );
        if ( scalar(@range) ) {
            $c->flash( error_msg =>
                    'Impossible delete vlan. There are subnets that belong to vlan:  ' .
                    $vlan->name );
            $c->stash( default_backref => $c->uri_for_action( '/vlan/view', [ $vlan->id ] ) );
            $c->detach('/follow_backref');
        }
        $vlan->delete;
        $c->flash( message => 'Success!! Vlan ' . $vlan->id . ' successful deleted.' );

        $c->stash( default_backref => $c->uri_for('/vlan/list') );
        $c->detach('/follow_backref');
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
