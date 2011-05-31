# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::App::Netwalker;

use Moose;
extends 'Manoc::App';

with qw(MooseX::Workers);

use Manoc::Netwalker::DeviceUpdater;

has 'device' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

my $Reports = {};

sub visit_device {
    my ($device_id, $device_set, $config) = @_;

    # my $device_entry = $self->schema->resultset('Device')->find( $device_id );
    # $device_entry or $self->log->logdie( $self->device, " not in device list" );

    # my $updater = Manoc::Netwalker::DeviceUpdater->new(
    #     entry      => $device_entry,
    #     config     => $config,
    #     device_set => $device_set,
    #     schema     => $self->schema,
    #     timestamp  => time
    # );
    # $updater->update_all_info();

    #print $updater->report->freeze;
    print @{POE::Filter::Reference->new->put([ {id => $device_id,
                                                report => "ohyeah", } 
                                              ])};
}

sub worker_stdout  {  
 my ( $self, $result ) = @_;

 $Reports->{$result->id} = $result->report; 
}

sub worker_manager_stop  { 

    use Data::Dumper;
    print Dumper($Reports);
}


sub run {
    my $self = shift;

    $self->log->info("Starting netwalker");

    # test code
    $self->device or die "Missing device";

    my @device_ids = $self->schema->resultset('Device')->get_column('id')->all;
    my %device_set = map { $_ => 1 } @device_ids;

    my %config = (
        snmp_community     => $self->config->{Credentials}->{snmp_community}   || 'public',
        snmp_version       => '2c',
        default_vlan       => $self->config->{Netwalker}->{default_vlan}       || 1,
        iface_filter       => $self->config->{Netwalker}->{iface_filter}       || 1,
        ignore_portchannel => $self->config->{Netwalker}->{ignore_portchannel} || 1,
    );

    my $n_procs =  $self->config->{Netwalker}->{n_procs} || 1;
    #set the number of parallel procs
    $self->max_workers($n_procs);
    

    # spawn workers
    foreach(@device_ids){
        $self->enqueue( visit_device($_, \%device_set, \%config)  );
        
    }

   POE::Kernel->run();
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
