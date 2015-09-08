# Copyright 2011-2014 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Device;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with "Manoc::ControllerRole::CommonCRUD";
with "Manoc::ControllerRole::JSONView";

use Text::Diff;
use Manoc::Form::Device;
use Manoc::Form::Uplink;

# moved  Manoc::Netwalker::DeviceUpdater to conditional block in refresh
# where we need it
use Module::Load;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Device - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'device',
        }
    },
    class      => 'ManocDB::Device',
    form_class => 'Manoc::Form::Device',
);

=head1 ACTIONS


=head2 view

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};
    my $id     = $device->id;

    my %tmpl_param;
    my @iface_info;

    $tmpl_param{uplinks} = join( ", ", map { $_->interface } $device->uplinks->all() );

    # CPD
    my@neighs = $device->neighs( {}, { prefetch=>'to_device_info' } );
  
    my @cdp_links;
    my $time_limit = $c->config->{Device}->{cdp_age} || 3600 * 12; #12 hours
    foreach my $n (@neighs){
	push ( @cdp_links, {  
	    expired      => time - $n->last_seen > $time_limit,
	    local_iface  => $n->from_interface,
	    to_device    => $n->to_device,
	    to_device_info => $n->to_device_info,
	    remote_id    => $n->remote_id,
	    remote_type  => $n->remote_type,
	    date         => $n->last_seen,
	});
    }
    
    #------------------------------------------------------------
    # Interfaces info
    #------------------------------------------------------------

    # prefetch notes
    my %if_notes = map { $_->interface => 1 } $device->ifnotes;

    # prefetch interfaces last activity
    my ($e, $it);

    $it = $c->model('ManocDB::IfStatus')->search_mat_last_activity($id);


    my %if_last_mat;

    while ( $e = $it->next ) {
      $if_last_mat{$e->interface} = $e->get_column('lastseen');
    }

    # fetch ifstatus and build result array
    my @ifstatus = $device->ifstatus;
    foreach my $r (@ifstatus) {
        my ( $controller, $port ) = split /[.\/]/, $r->interface;
        my $lc_if = lc( $r->interface );

        push @iface_info, {
            controller   => $controller,      # for sorting
            port         => $port,            # for sorting
            interface    => $r->interface,
            speed        => $r->speed || 'n/a',
            up           => $r->up || 'n/a',
            up_admin     => $r->up_admin || '',
            duplex       => $r->duplex || '',
            duplex_admin => $r->duplex_admin || '',
            cps_enable   => $r->cps_enable && $r->cps_enable eq 'true',
            cps_status   => $r->cps_status  || '',
            cps_count    => $r->cps_count   || '',
            description  => $r->description || '',
            vlan         => $r->vlan        || '',
            last_mat     => $if_last_mat{ $r->interface },
            has_notes => ( exists( $if_notes{$lc_if} ) ? 1 : 0 ),
        };
    }

    #Unused interfaces
    my @unused_ifaces = $c->model('ManocDB::IfStatus')->search_unused($id);

    #------------------------------------------------------------
    # wireless info
    #------------------------------------------------------------

    # ssid
    my @ssid_list = map +{
        interface => $_->interface,
        ssid      => $_->ssid,
        broadcast => $_->broadcast ? 'yes' : 'no',
        channel   => $_->channel
        },
        $device->ssids;

    # wireless clients
    my @dot11_clients = map +{
        ssid    => $_->ssid,
        macaddr => $_->macaddr,
        ipaddr  => $_->ipaddr,
        vlan    => $_->vlan,
        quality => $_->quality . '/100',
        state   => $_->state,
    }, $device->dot11clients;

    # prepare template
    $c->stash( template => 'device/view.tt' );
    $c->stash(%tmpl_param);

    $c->stash(
        iface_info    => \@iface_info,
        cdp_links     => \@cdp_links,
        ssid_list     => \@ssid_list || undef,
        dot11_clients => \@dot11_clients || undef,
        unused_ifaces => \@unused_ifaces
    );
}

=head2 refresh

=cut

sub refresh : Chained('object') : PathPart('refresh') : Args(0) {
    my ( $self, $c ) = @_;
    my $device_id = $c->stash->{object}->id;
    
    my $has_netwalker = eval { load Manoc::Device::Netwalker; 1 };
    if (!$has_netwalker) {
	$c->flash( error_msg => "Netwalker not installer");
	$c->response->redirect(
			       $c->uri_for_action( '/device/view', [$device_id] ) );
	$c->detach();
    }

    my %config = (
	snmp_community => $c->config->{Credentials}->{snmp_community}
	    || 'public',
	snmp_version   => $c->config->{Netwalker}->{snmp_version} || 2,
	default_vlan       => $c->config->{Netwalker}->{default_vlan} || 1,
	iface_filter       => $c->config->{Netwalker}->{iface_filter} || 1,
	ignore_portchannel => $c->config->{Netwalker}->{ignore_portchannel}
	    || 1,
    );
    
    my $updater = Manoc::Netwalker::DeviceUpdater->new(
         entry        => $c->stash->{object},
         config       => \%config,
         schema       => $c->model('ManocDB'),
         timestamp    => time
     );
   
    my $ret_status = $updater->update_all_info();
    unless(defined($ret_status)){
	my $err_msg = "Error! An error occurred while retrieving infos. See the logs for details.";
	$c->flash( error_msg => $err_msg );
	$c->response->redirect(
	    $c->uri_for_action( '/device/view', [$device_id] ) );
	$c->detach();
    }

    my $msg = "Success! Device infomations are now up to date.";
    $c->flash( message => $msg);
    $c->response->redirect(
			   $c->uri_for_action( '/device/view', [$device_id] ) );
}


=head2 uplinks

=cut

sub uplinks : Chained('object') : PathPart('uplinks') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{'object'};
    my $form = Manoc::Form::Uplink->new(device => $device);

    if ($device->ifstatus->count() == 0) {
        $c->flash(error_msg => 'No known interfaces on this device');
        $c->uri_for_action( 'device/view', [ $device->id ] );
        $c->detach();
    }
    $c->stash(
        form   => $form,
        action => $c->uri_for($c->action, $c->req->captures),
    );
    return unless $form->process(
        params =>  $c->req->parameters,
    );

    $c->response->redirect(
	$c->uri_for_action( 'device/view', [ $device->id ] )
    );
    $c->detach();
}


=head2 get_object_list

=cut

sub get_object_list {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};
    my @devices = $rs->search(
        {},
        {
            prefetch => [ { 'rack' => 'building' }, 'mng_url_format', ]
        }
    );
    return \@devices;
}

=head2 show_run

Show running configuration

=cut

sub show_config : Chained('object') : PathPart('config') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{object};
    my $config = $device->config;

    my $prev_config = $config->prev_config;
    my $curr_config = $config->config;

    #Get diff and modify diff string
    my $diff = diff( \$prev_config, \$curr_config );

    #Clear "@@...@@" stuff
    $diff =~ s/@@[^@]*@@/<hr>/g;

    #Insert HTML "font" tag to color "+" and "-" rows
    $diff =~ s/^\+(.*)$/<font color=green> $1<\/font>/mg;
    $diff =~ s/^\-(.*)$/<font color=red> $1<\/font>/mg;

    #Prepare template
    $c->stash(
	config => $config,
	diff   => $diff,
    );
    $c->stash( template => 'device/config.tt' );

}


=head2 create

=cut


before 'create' => sub {
    my ( $self, $c) = @_;

    my $rack_id = $c->req->query_parameters->{'rack'};
    $c->log->debug("new device in $rack_id");
    $c->stash(form_defaults => { rack => $rack_id });
};

=head1 METHODS

=cut

sub get_object {
    my ( $self, $c, $id ) = @_;

    my $object = $c->stash->{resultset}->find($id);
    if ( !defined($object)) {
	$object = $c->stash->{resultset}->find({mng_address => $id});
    }
    return $object;
}

=head2 delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};
    my $id     = $device->id;
    my ( $e, $it );

    # transaction....
    # 1) create a new deletedevice d2
    # 2) move mat for $device to archivedmat for d2
    # 3) $device->delete
    $c->model('ManocDB')->schema->txn_do(
	sub {
	    my $del_device = $c->model('ManocDB::DeletedDevice')->create(
                    {
                        ipaddr    => $id,
                        name      => $device->name,
                        model     => $device->model,
                        vendor    => $device->vendor,
                        timestamp => time()
                    }
                );
	    $it = $c->model('ManocDB::Mat')->search(
		{ device => $id, },
		{
                        select => [
                            'macaddr', 'vlan',
                            { 'min' => 'firstseen' }, { 'max' => 'lastseen' },
                        ],
                        group_by => [qw(macaddr vlan)],
                        as       => [ 'macaddr', 'vlan', 'min_firstseen', 'max_lastseen' ]
                    }
	    );

	    while ( $e = $it->next ) {
		$del_device->add_to_mat_assocs(
		    {
			macaddr   => $e->macaddr,
			firstseen => $e->get_column('min_firstseen'),
			lastseen  => $e->get_column('max_lastseen'),
			vlan      => $e->vlan
		    }
		);
	    }
	    $device->delete;
	}
    );

    if ($@) {
	$c->flash( error_msg => 'Error deleting device: ' . $@ );
	return undef;
    }
    return 1;
}


=head2 prepare_json_object

=cut

sub prepare_json_object  {
    my ($self, $device) = @_;
    return {
	id   => $device->id,
	name => $device->name,
	rack => $device->rack->id,
    };
};

=head1 AUTHOR

Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
