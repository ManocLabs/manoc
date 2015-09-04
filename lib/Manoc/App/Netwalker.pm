# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::App::Netwalker;

use Moose;
extends 'Manoc::App';

with qw(MooseX::Workers);
use POE qw(Filter::Reference Filter::Line);

use Data::Dumper;
use Manoc::Netwalker::DeviceUpdater;
use Manoc::Report::NetwalkerReport;

has 'device' => (
                 is      => 'ro',
                 isa     => 'Str',
                 default => '',
                );

has 'force_update' => (
                 is      => 'ro',
                 isa     => 'Bool',
                 default => 0,
                 required=> 0,
                );

has 'full_update' => (
                 traits   => ['NoGetopt'],
                 is       => 'ro',
                 isa      => 'Bool',
                 lazy_build  => 1,
                );

has 'n_procs' => (
                 traits   => ['NoGetopt'],
                 is       => 'ro',
                 isa      => 'Int',
                 lazy_build  => 1,
                );


sub _build_full_update {
    my $self  = shift;
    my $timestamp = time;
    my $if_update_interval = $self->config->{Netwalker}->{ifstatus_interval} || 0;
    #if the update was forced or interval == 0 refresh info
    return 1 if($self->force_update or !$if_update_interval );

    my $if_last_update_entry =
      $self->schema->resultset('System')->find("netwalker.if_update");
    if (!$if_last_update_entry) {
        $if_last_update_entry =  
          $self->schema->resultset('System')->create({ 
                                                      name  => "netwalker.if_update",
                                                      value => "0"});
    }
    my $if_last_update = $if_last_update_entry->value();
    my $elapsed_time   = $timestamp - $if_last_update;

    return $elapsed_time > $if_update_interval ? 1 : 0;
}

sub _build_n_procs{
    my $self = shift;
    return $self->config->{Netwalker}->{n_procs} || 1;
}

sub visit_device {
    my ($self, $device_id, $config, $update) = @_;

    my $device_entry = $self->schema->resultset('Device')->find($device_id);
    unless($device_entry){
        $self->log->error("$device_id not in device list");
        return;
    }
    my $updater = Manoc::Netwalker::DeviceUpdater->new(
                                                       entry           => $device_entry,
                                                       config          => $config,
                                                       schema          => $self->schema,
                                                       timestamp       => time,
                                                      );
    #deep update?
    my $device_ip = $device_entry->id->address;
    if($self->full_update){
        $updater->update_all_info();
        #update vtp info if is also a vtp server 
        $config->{vtp_servers}->{$device_ip} and $updater->update_vtp_database();
    }
    else {
        $updater->fast_update();
    }
    print @{POE::Filter::Reference->new->put([{ report => $updater->report->freeze  }])};
}

sub worker_stderr  {
    my ( $self, $stderr_msg ) = @_;  

    print $stderr_msg,"\n"
}
 
sub worker_stdout  {  
    my ( $self, $result ) = @_;

    #accumulate Manoc::Report::NetwalkerReport
    my $worker_report = Manoc::Netwalker::DeviceReport->thaw($result->{report});
    my $id_worker = $worker_report->host;

    $self->log->debug("Device $id_worker is up to date");
}

sub stdout_filter  { POE::Filter::Reference->new }
sub stderr_filter  { POE::Filter::Line->new }

sub set_update_status {
    my  $self  = shift;
    my $if_last_update_entry =
      $self->schema->resultset('System')->find("netwalker.if_update");
    $if_last_update_entry->value(time);
    $if_last_update_entry->update();
}

sub worker_manager_stop  { 
    my $self  = shift;

    #update netwalker.if_status variable
    $self->full_update and $self->set_update_status();
}

sub run {
    my $self = shift;
    my @device_ids;

    $self->log->info("Starting netwalker");

    my %config = (
                  snmp_community       => $self->config->{Credentials}->{snmp_community}   || 'public',
                  snmp_version         => $self->config->{Netwalker}->{snmp_version}       || 2,
                  default_vlan         => $self->config->{Netwalker}->{default_vlan}       || 1,
                  iface_filter         => $self->config->{Netwalker}->{iface_filter}       || 1,
                  ignore_portchannel   => $self->config->{Netwalker}->{ignore_portchannel} || 1,
                  vtp_server           => $self->config->{Netwalker}->{vtp_server} || '',
                  mat_force_vlan       => $self->config->{Netwalker}->{mat_force_vlan} || '',
                 ); 

   #parse vtp servers
   my $vtp_server_conf = $self->config->{Netwalker}->{vtp_server};
    if ($vtp_server_conf) {
	my @address_list = split /\s+/, $vtp_server_conf;
	$config{vtp_servers} = { map { $_ => 1 } @address_list };
    } else {
	$self->log->info("no VTP servers defined");
    }

    $self->max_workers($self->n_procs);
    
    #prepare the device list to visit
    if ($self->device) {
        push @device_ids, $self->device;
    } else {
        #prepare full_update variable (to avoid concurrency problems)
        $self->full_update();
        @device_ids = $self->schema->resultset('Device')->get_column('id')->all;
    }

    foreach my $ids (@device_ids) {
        $self->enqueue( sub {  $self->visit_device($ids, \%config)  } );
    }
    POE::Kernel->run();
}


no Moose;                       # Clean up the namespace.
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
