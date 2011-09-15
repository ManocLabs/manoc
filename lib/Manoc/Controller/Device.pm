# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Device;
use Moose;
use namespace::autoclean;
use Manoc::Utils qw(clean_string print_timestamp check_addr );
use Text::Diff;
use Manoc::Form::DeviceNew;
use Manoc::Form::DeviceEdit;
use Manoc::Netwalker::DeviceUpdater;
use Manoc::Report::NetwalkerReport;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Device - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect('/device/list');
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('device') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::Device') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) {

    # $id = primary key
    my ( $self, $c, $id ) = @_;

    return if ( $id eq '' );
    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !defined( $c->stash->{object} ) ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};
    my $id     = $device->id;

    my %tmpl_param;
    my @iface_info;

    $tmpl_param{name}     = $device->name;
    $tmpl_param{boottime} = (
        $device->boottime ? print_timestamp( $device->boottime ) :
            'n/a'
    );
    $tmpl_param{last_visited} = (
        $device->last_visited ? print_timestamp( $device->last_visited ) :
            'Never visited'
    );

    $tmpl_param{backup_date} =
        $device->config ? print_timestamp( $device->config->config_date ) : undef;
    $tmpl_param{backup_enabled} = $device->backup_enabled ? "Enabled" : "Not enabled";

    $tmpl_param{dot11_enabled} = $device->get_dot11 ? "Enabled" : "Not enabled";
    $tmpl_param{arp_enabled}   = $device->get_arp   ? "Enabled" : "Not enabled";
    $tmpl_param{mat_enabled}   = $device->get_mat   ? "Enabled" : "Not enabled";
    $tmpl_param{uplinks} = join( ", ", map { $_->interface } $device->uplinks->all() );

    # CPD
    my @neighs = $c->model('ManocDB::CDPNeigh')->search(
                 { from_device => $id },
                 {
                     '+columns' => [ { 'name' => 'dev.name' } ],
                     order_by   => 'last_seen DESC, from_interface',
                     from  => [
                               { 'me' => 'cdp_neigh' },  
                               [
                                { 
                                    'dev'       => 'devices',
                                    -join_type  => 'LEFT',
                                },
                                { 
                                    'me.to_device' => 'dev.id'}
                                ]
                               ]});

    



    my @cdp_links = map {
        from_iface    => $_->from_interface,
            to_device => $_->to_device,
            to_iface  => $_->to_interface,
            date      => print_timestamp( $_->last_seen ),
            to_name   => $_->get_column('name'),
    }, @neighs;


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
      
      $if_last_mat{$e->interface} =
	$e->get_column('lastseen') ? 
	  print_timestamp( $e->get_column('lastseen') ) : 'never';
    }

    # fetch ifstatus and build result array
    my @ifstatus = $device->ifstatus;
    foreach my $r (@ifstatus) {
        my ( $controller, $port ) = split /[.\/]/, $r->interface;
        my $lc_if = lc( $r->interface );

        push @iface_info, {
            controller   => $controller,                                  # for sorting
            port         => $port,                                        # for sorting
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
            updown_status_link => '',    #updown_status_link?device=$id&iface=".$r->interface,
            enable_updown => check_enable_updown( $r->interface, @cdp_links ),
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
        detail_link => '',    #$app->manoc_url("dot11client?device=$id&macaddr=" . $_->macaddr),
        },
        $device->dot11clients;

    # prepare template
    $c->stash( template => 'device/view.tt' );
    $c->stash(%tmpl_param);


    use URL::Encode;

    $c->stash(
        iface_info    => \@iface_info,
        cdp_links     => \@cdp_links,
        ssid_list     => \@ssid_list || undef,
        dot11_clients => \@dot11_clients || undef,
        unused_ifaces => \@unused_ifaces
    );
}

sub check_enable_updown {
    my ( $interface, @cdp_links ) = @_;

    #CDP link check
    foreach (@cdp_links) {
        $_->{from_iface} eq $interface and return 0;
    }

    return 1;
}



=head2 refresh

=cut

sub refresh : Chained('object') : PathPart('refresh') : Args(0) {
    my ( $self, $c ) = @_;
    my $device_id = $c->stash->{object}->id;


     my %config = (
         snmp_community => $c->config->{Credentials}->{snmp_community}
           || 'public',
         snmp_version       => '2c',
         default_vlan       => $c->config->{Netwalker}->{default_vlan} || 1,
         iface_filter       => $c->config->{Netwalker}->{iface_filter} || 1,
         ignore_portchannel => $c->config->{Netwalker}->{ignore_portchannel}
           || 1,
         update_ifstatus_interval => $c->config->{Netwalker}->{ifstatus_interval} || 0,
         vtpstatus_interval => $c->config->{Netwalker}->{vtpstatus_interval}
		   || 0,
     );

     $ENV{DEBUG} = 0;
     my $updater = Manoc::Netwalker::DeviceUpdater->new(
         entry        => $c->stash->{object},
         config       => \%config,
         schema       => $c->model('ManocDB'),
         force_update => 1,
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
    
      my $worker_report = $updater->report;
      my $report        = Manoc::Report::NetwalkerReport->new;

      #create the report
      my $errors = $worker_report->error;
      scalar(@$errors) and $report->add_error(
          {
              id       => $device_id,
              messages => $errors
          }
      );
      my $warning = $worker_report->warning;
      scalar(@$warning) and $report->add_warning(
          {
              id       => $device_id,
              messages => $warning
          }
      );

      $report->mat_entries( $worker_report->mat_entries );
      $report->arp_entries( $worker_report->arp_entries );
      $report->cdp_entries( $worker_report->cdp_entries );
      $report->new_devices( $worker_report->new_devices );
      $report->visited( $worker_report->visited );

      my $new_report = $c->model('ManocDB::ReportArchive')->create(
          {
              'timestamp' => time,
              'name'      => 'Netwalker',
              'type'      => 'NetwalkerReport',
              's_class'   => $report,
          }
      );

      my $report_url =
        $c->uri_for_action( '/reportarchive/view', [ $new_report->id ] );

      my $msg = "Success! Device infomations are now up to date!"
        . " See the <a href=\"$report_url\">report</a> for details.";

    $c->flash( message => $msg);
    $c->response->redirect(
			   $c->uri_for_action( '/device/view', [$device_id] ) );
    $c->detach();

}

=head2 list

=cut

sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    my $device_schema = $c->stash->{resultset};

    my @device_table = $device_schema->search(
        undef,
        {
            join     => [ { rack   => 'building' }, 'mng_url_format' ],
            prefetch => [ { 'rack' => 'building' }, 'mng_url_format', ]
        }
    );
    $c->stash( device_table => \@device_table );
    $c->stash( template     => 'device/list.tt' );

}

=head2 show_run

Show running configuration

=cut

sub show_run : Chained('object') : PathPart('show_run') : Args(0) {
    my ( $self, $c ) = @_;

    my $device_schema = $c->stash->{resultset};
    my $device_id     = $c->stash->{object}->id;

    my (
        $dev_config, $curr_config,     $curr_date, $prev_config,
        $prev_date,  $has_prev_config, $template,  %tmpl_param
    );

    #Retrieve device configuration from DB
    $dev_config = $c->model('ManocDB::DeviceConfig')->find( {device => $device_id} );
    if ( !$dev_config ) {
        $c->stash( error_msg => "Device backup not found!" );
        $c->detach('/error/index');
    }

    #Set configuration parameters
    $prev_config = $dev_config->prev_config;
    if ( defined($prev_config) ) {
        $has_prev_config = 1;
        $prev_date       = print_timestamp( $dev_config->prev_config_date );
    }
    else {
        $has_prev_config = 0;
        $prev_date       = "";
    }
    $curr_config = $dev_config->config;
    $curr_date   = print_timestamp( $dev_config->config_date );

    #Get diff and modify diff string
    my $diff = diff( \$prev_config, \$curr_config );

    #Clear "@@...@@" stuff
    $diff =~ s/@@[^@]*@@/<hr>/g;

    #Insert HTML "font" tag to color "+" and "-" rows
    $diff =~ s/^\+(.*)$/<font color=green> $1<\/font>/mg;
    $diff =~ s/^\-(.*)$/<font color=red> $1<\/font>/mg;

    $tmpl_param{prev_config}      = $prev_config;
    $tmpl_param{prev_config_date} = $prev_date;
    $tmpl_param{has_prev_config}  = $has_prev_config;
    $tmpl_param{curr_config}      = $curr_config;
    $tmpl_param{curr_config_date} = $curr_date;
    $tmpl_param{diff}             = $diff;

    #Prepare template
    $c->stash(%tmpl_param);
    $c->stash( template => 'device/show_run.tt' );

}

=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args() {
    my ( $self, $c, $rack_id ) = @_;

    my $item = $c->stash->{resultset}->new_result( {} );
    $c->stash( def_rack => $rack_id ) if ($rack_id);
    $c->stash( default_backref => $c->uri_for_action('device/list') );
    my $form = Manoc::Form::DeviceNew->new( item => $item );

    #prepare the selects input
    my @buildings = $c->model('ManocDB::Building')->search(
        {},
        {
            order_by => 'me.id',
            prefetch => 'racks',
            join     => 'racks',
        }
    );
    my @racks = $c->model('ManocDB::Rack')->search(
        {},
        {
            join     => 'building',
            prefetch => 'building'
        }
    );

    $c->stash( form      => $form );
    $c->stash( template  => 'device/create.tt' );
    $c->stash( buildings => \@buildings );
    $c->stash( racks     => \@racks );

    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }
    my $param = $c->req->params;
    if ( defined( $param->{'building'} ) ) {
        delete $param->{'building'};
    }

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened
    unless ( $form->process( params => $param ) ) {
        $c->keep_flash('backref');
        return;
    }
    $c->flash( message => 'Success! Device created.' );
    $c->keep_flash('backref');
    $c->response->redirect( $c->uri_for_action( '/device/edit', [ $c->req->param('id') ] ) );
    $c->detach();
}

=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{object};
    my $id   = $item->id;
    my $form = Manoc::Form::DeviceEdit->new( item => $item );

    $c->keep_flash('backref');

    $c->stash( default_backref => $c->uri_for_action( 'device/view', [$id] ) );

    #prepare the selects input

    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }

    $c->stash( form => $form, template => 'device/edit.tt' );

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened
    return unless $form->process( params => $c->req->params, );
    $c->flash( message => 'Success! Device edit.' );
    $c->detach('/follow_backref');
}

=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};
    my $id     = $device->id;
    my ( $e, $it );

    $c->stash( default_backref => $c->uri_for_action('device/list') );
    if ( lc $c->req->method eq 'post' ) {
        $c->model('ManocDB')->schema->txn_do(
            sub {

                # transaction....
                # 1) create a new deletedevice d2
                # 2) move mat for $device to archivedmat for d2
                # 3) $device->delete
                my $del_device = $c->model('ManocDB::DeletedDevice')->create(
                    {
                        ipaddr    => $device->id,
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
            $c->flash( error_msg => 'Commit error: ' . $@ );
            $c->detach('/error/index');
        }

        $c->flash( message => 'Success!! Device ' . $id . ' successful deleted.' );

        $c->detach('/follow_backref');

    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

=head2 change_ip

=cut

sub change_ip : Chained('object') : PathPart('change_ip') : Args(0) {

    #  my ($self, $c) = @_;

    #N.B. ho provato con FH ma da' errore nel momento in cui fa l'update (da aggiornare il modello?)
    #   my $item = $c->stash->{'object'};
    #   my $id   = $item->id;
    #   $c->log->debug(Dumper($item));
    #   my $form = Manoc::Form::Change_ip->new(item => $item);

    #   $c->stash( form => $form, template => 'device/change_ip.tt' );

    #   # the "process" call has all the saving logic,
    #   #   if it returns False, then a validation error happened
    #   return unless $form->process( params => $c->req->params, );

    #   $c->flash(message => 'Success! The IP of the device is changed.');

    #   if(my $backref = $c->check_backref($c) ){
    #       $c->response->redirect($backref);
    #       $c->detach();
    #   }
    #   $c->response->redirect($c->uri_for_action
    # 			 ('/device/view', [$c->req->param('id')]));
    #   $c->detach();
    # }
    my ( $self, $c ) = @_;
    my $error = {};
    my $old_ip = $c->stash->{'object'}->id || $c->req->param('id');
    $c->stash( template => 'device/change_ip.tt' );

    my $message;
    if ( $c->req->param('submit') ) {
        my $done;
        my $new_ip = $c->req->param('new_ip');
        ( $done, $message ) = $self->process_change_ip( $c, $old_ip, $new_ip );
        if ($done) {
            $c->flash( message => 'Success! Device edit.' );

            if ( my $backref = $c->check_backref($c) ) {
                $c->response->redirect($backref);
                $c->detach();
            }
            $c->response->redirect( $c->uri_for_action( '/device/view', [$new_ip] ) );
            $c->detach();
        }
        else {
            $error->{ip} = $message;
            $c->stash( error  => $error );
            $c->stash( new_ip => $c->req->param('new_ip') );
        }
    }
    elsif ( $c->req->param('discard') ) {
        if ( my $backref = $c->check_backref($c) ) {
            $c->response->redirect($backref);
            $c->detach();
        }
        $c->response->redirect( $c->uri_for_action( '/device/view', [$old_ip] ) );
        $c->detach();
    }
}

sub process_change_ip : Private {
    my ( $self, $c, $id, $new_id ) = @_;
    my $device = $c->stash->{'object'};
    my $new_ip = $c->stash->{'resultset'}->find($new_id);

    if ($new_ip) {
        return ( 0, "The ip is already in use. Try again with another one!" );
    }
    if ( check_addr($new_id) ) {

        $c->model('ManocDB')->schema->txn_do(
            sub {
                $device->update( { id => $new_id } );
            }
        );
        if ($@) {
            return ( 0, $@ );
        }
        else {
            return ( 1, "" );
        }
    }
    else {
        return ( 0, 'Bad ip format' );
    }
}

=head2 uplinks

=cut

sub uplinks : Chained('object') : PathPart('uplinks') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{'object'};

    if ( $c->req->param('discard') ) {
        $c->response->redirect( $c->uri_for_action( 'device/view', [ $device->id ] ) );
        $c->detach();
    }
    my $message;
    if ( $c->req->param('submit') ) {
        my $done;
        ( $done, $message ) = $self->process_uplinks( $c, $device );
        $done and $c->flash( message => $message );

        if ( my $backref = $c->check_backref($c) ) {
            $c->response->redirect($backref);
            $c->detach();
        }
        $done and
            $c->response->redirect( $c->uri_for_action( '/device/view', [ $device->id ] ) );
        $c->detach();
    }

    my %uplinks = map { $_->interface => 1 } $device->uplinks->all;
    my @iface_list;
    my $rs = $device->ifstatus;
    while ( my $r = $rs->next() ) {
        my ( $controller, $port ) = split /[.\/]/, $r->interface;
        my $lc_if = lc( $r->interface );

        push @iface_list, {
            controller  => $controller,                 # for sorting
            port        => $port,                       # for sorting
            interface   => $r->interface,
            description => $r->description || '',
            checked     => $uplinks{ $r->interface },
        };
    }
    @iface_list =
        sort { ( $a->{controller} cmp $b->{controller} ) || ( $a->{port} <=> $b->{port} ) }
        @iface_list;
    $c->stash(
        template   => 'device/uplinks.tt',
        iface_list => \@iface_list
    );

}

sub process_uplinks : Private {
    my ( $self, $c ) = @_;
    my @uplinks = $c->req->param('uplinks');

    #return (1, 'Done') unless @uplinks ;

    $c->model('ManocDB')->schema->txn_do(
        sub {
            $c->stash->{'object'}->uplinks()->delete();
            foreach (@uplinks) {
                $c->stash->{'object'}->add_to_uplinks( { interface => $_ } );
            }
        }
    );
    return ( 1, 'Done. Uplinks setted.' );
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
