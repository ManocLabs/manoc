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

has 'report' => (
                 traits   => ['NoGetopt'],
                 is       => 'rw',
                 isa      => 'Manoc::Report::NetwalkerReport',
                 required => 0,
                 default  => sub { Manoc::Report::NetwalkerReport->new },
                );

has 'force_update' => (
                 is      => 'ro',
                 isa     => 'Bool',
                 default => 0,
                 required=> 0,
                );


sub get_update_status {
    my ( $self, $if_update_interval ) = @_;
    my $timestamp = time;
    #if the update was forced or interval == 0 refresh info
    return 1 if($self->force_update or !$if_update_interval );

    my $if_last_update_entry =
      $self->schema->resultset('System')->find("netwalker.if_update");
    if (!$if_last_update_entry) {
        $if_last_update_entry =  $self->schema->resultset('System')->create({
                                                                             name  => "netwalker.if_update",
                                                                             value => "0"});
    }
    my $if_last_update = $if_last_update_entry->value();
    my $elapsed_time   = $timestamp - $if_last_update;

    return $elapsed_time > $if_update_interval ? 1 : 0;
}

sub set_update_status {
    my  $self  = shift;
    my $if_last_update_entry =
      $self->schema->resultset('System')->find("netwalker.if_update");
    $if_last_update_entry->value(time);
    $if_last_update_entry->update();
}

sub visit_device {
    my ($self, $device_id, $config, $update) = @_;

    my $device_entry = $self->schema->resultset('Device')->find( $device_id );
    unless($device_entry){
        $self->log->error("$device_id not in device list");
        return;
    }
    my $updater = Manoc::Netwalker::DeviceUpdater->new(
                                                       entry           => $device_entry,
                                                       config          => $config,
                                                       schema          => $self->schema,
                                                       timestamp       => time,
                                                       update_ifstatus => $update,
                                                      );
    $updater->update_all_info();

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

    my $errors = $worker_report->error;
    scalar(@$errors) and $self->report->add_error({id       => $id_worker,
                                                   messages =>  $errors });
    my $warning = $worker_report->warning;
    scalar(@$warning) and $self->report->add_warning({id      => $id_worker,
                                                      messages=> $warning});

    $self->report->update_stats({
                                 mat_entries => $worker_report->mat_entries,
                                 arp_entries => $worker_report->arp_entries,
                                 cdp_entris  => $worker_report->cdp_entries,
                                 new_devices => $worker_report->new_devices,
                                 visited     => $worker_report->visited,
                                });
}

sub stdout_filter  { POE::Filter::Reference->new }
sub stderr_filter  { POE::Filter::Line->new }

sub worker_manager_stop  { 
    my $self  = shift;
    $self->schema->resultset('ReportArchive')->create(
                                                      {
                                                       'timestamp' => time,
                                                       'name'      => 'Netwalker',
                                                       'type'      => 'NetwalkerReport',
                                                       's_class'   => $self->report,
                                                      }
                                                     );
    $self->log->debug(Dumper($self->report));
}


sub run {
    my $self = shift;
    my @device_ids;

    $self->log->info("Starting netwalker");

    my %config = (
                  snmp_community       => $self->config->{Credentials}->{snmp_community}   || 'public',
                  snmp_version         => '2c',
                  default_vlan         => $self->config->{Netwalker}->{default_vlan}       || 1,
                  iface_filter         => $self->config->{Netwalker}->{iface_filter}       || 1,
                  ignore_portchannel   => $self->config->{Netwalker}->{ignore_portchannel} || 1,
                  vtpstatus_interval   => $self->config->{Netwalker}->{vtpstatus_interval} || 0,
                 ); 

    #deep update?
    my $update_all = $self->get_update_status($self->config->{Netwalker}->{ifstatus_interval} || 0);
    #update netwalker.if_status variable
    $update_all and $self->set_update_status();

    my $n_procs =  $self->config->{Netwalker}->{n_procs} || 1;

    $self->max_workers($n_procs);

    #prepare the device list to visit
    if ($self->device) {
        push @device_ids, $self->device;
    } else {
        @device_ids = $self->schema->resultset('Device')->get_column('id')->all;
    }

    foreach my $ids (@device_ids) {
        $self->enqueue( sub {  $self->visit_device($ids, \%config, $update_all)  } );
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
