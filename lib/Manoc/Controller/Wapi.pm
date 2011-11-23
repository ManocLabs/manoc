# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Wapi;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use strict;
use warnings;

use YAML::Syck;

use Encode;
use POSIX qw(strftime);
use Data::Dumper;
use Manoc::Utils qw(padded_ipaddr);

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('manoc wapi');
    $c->detach();
}

sub apierror : Private {
    my ( $self, $c ) = @_;

    $c->response->status(400);
    $c->response->body( $c->stash->{error} );
    $c->detach();
}

sub base : Chained('/') : PathPart('wapi') : CaptureArgs(0) {
}

sub winlogon : Chained('base') : PathPart('winlogon') : Args(0) {
    my ( $self, $c ) = @_;

    my $user   = $c->req->param('user');
    my $ipaddr = $c->req->param('ipaddr');

    unless ($user) {
        $c->stash( error => "Missing user param" );
        $c->detach('apierror');
    }
    unless ( $ipaddr =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/o ) {
        $c->stash( error => "Bad ipaddr" );
        $c->detach('apierror');
    }

    my $timestamp = time();

    if ( $user =~ /([^\$]+)\$$/ ) {

        # computer logon

        my $name = $1;

        my $rs = $c->model('ManocDB::WinHostname');

        my @entries = $rs->search(
            {
                ipaddr   => padded_ipaddr($ipaddr),
                name     => $name,
                archived => 0
            }
        );

        if ( scalar(@entries) > 1 ) {
            $c->response->body("Error");
            $c->detach();
        }

        if (@entries) {
            my $entry = $entries[0];
            $entry->lastseen($timestamp);
            $entry->update();
        }
        else {
            $rs->create(
                {
                    ipaddr    => $ipaddr,
                    name      => $name,
                    firstseen => $timestamp,
                    lastseen  => $timestamp,
                    archived  => 0
                }
            );
        }

    }
    else {

        # user logon

        my $rs      = $c->model('ManocDB::WinLogon');
        my @entries = $rs->search(
            {
                user     => $user,
                ipaddr   => padded_ipaddr($ipaddr),
                archived => 0
            }
        );

        if ( scalar(@entries) > 1 ) {
            $c->response("Error");
            $c->detach();
        }

        if (@entries) {
            my $entry = $entries[0];
            $entry->lastseen($timestamp);
            $entry->update();
        }
        else {
            $rs->create(
                {
                    ipaddr    => $ipaddr,
                    user      => lc($user),
                    firstseen => $timestamp,
                    lastseen  => $timestamp,
                    archived  => 0
                }
            );
        }
    }
    $c->response->body('ok');
    $c->detach();
}

#----------------------------------------------------------------------#

sub dhcp_leases : Chained('base') : PathPart('dhcp_leases') : Args(0) {
    my ( $self, $c ) = @_;

    my $rs  = $c->model('ManocDB::DHCPLease');
    my $req = $c->req;

    my $server = $req->param('server');
    $server ||= $req->hostname();

    my $data = $req->body || undef;
    $c->detach unless(defined $data);
    
    my @records = LoadFile($data);

    $c->detach() unless(scalar(@records));

    $rs->search( { server => $server } )->delete();

    my $n_created = 0;
    foreach my $r (@records) {
         my $macaddr = $r->{macaddr} or next;
         my $ipaddr  = $r->{ipaddr}  or next;
         my $start   = $r->{start}   or next;
         my $end     = $r->{end}     or next;

         my $hostname = $r->{hostname};
         my $status   = $r->{status};

         $rs->update_or_create(
             {
                 server   => $server,
                 macaddr  => $macaddr,
                 ipaddr   => $ipaddr,
                 hostname => $hostname,
                 start    => $start,
                 end      => $end,
                 status   => $status,
             }
         );
         $n_created++;
     }
    $c->response->body( "$server: $n_created/" . scalar(@records) );
    $c->detach();
}

sub dhcp_reservations : Chained('base') : PathPart('dhcp_reservations') : Args(0) {
    my ( $self, $c ) = @_;

    my $rs  = $c->model('ManocDB::DHCPReservation');
    my $req = $c->req;

    my $server = $req->param('server');
    $server ||= $req->hostname();

    my $data = $req->body() || '';
    my @records = LoadFile($data);
    $c->detach() unless(scalar(@records));

    $rs->search( { server => $server } )->delete();

    my $n_created = 0;
    foreach my $r (@records) {
        my $macaddr  = $r->{macaddr}  or next;
        my $ipaddr   = $r->{ipaddr}   or next;
        my $hostname = $r->{hostname} or next;
        my $name     = $r->{name}     or next;

        $rs->create(
            {
                server   => $server,
                macaddr  => $macaddr,
                ipaddr   => $ipaddr,
                name     => $name,
                hostname => $hostname,
            }
        );
        $n_created++;
    }

    $c->response->body( "$server: $n_created/" . scalar(@records) );
    $c->detach();
}

#----------------------------------------------------------------------#

1;
