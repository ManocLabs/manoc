# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Manifold::SSH::Fortigate;

use Moose;
use Try::Tiny;

with 'Manoc::ManifoldRole::SSH';

use File::Temp qw/ tempfile  /;

around '_build_username' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() || 'root';
};

has 'status' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_status'
);

sub _build_status {
    my $self = shift;
    return $self->cmd('get system status');
}

sub _build_boottime {
    my $self = shift;
    my ($days,$hours,$min);
    my $seconds_hour = 60 * 60;
    my $seconds_day  = 24 * $seconds_hour;

    my $data = $self->cmd('get system performance status');
    $data =~ m/.*Uptime:\s+(\d+) days,\s+(\d+) hours,\s+(\d+) minutes/ and 
    ($days,$hours,$min) = ($1,$2,$3);
    if(defined $days and defined $hours and defined $min) {
        my $uptime_seconds = time() - int(($days * $seconds_day) + ($hours * $seconds_hour) + ($min * 60));
        #$self->log->debug("Uptime in seconds: $uptime_seconds");
        return $uptime_seconds;
    }
}

sub _build_name {
    my $self = shift;
    $self->status =~ m/Hostname:\s+(.+)/;
    #$self->log->debug("Hostaname: $1");
    return $1;
}

sub _build_os {
    my $self = shift;
    return "FortiOS";
}

sub _build_os_ver {
    my $self = shift;
    $self->status =~ m/Version:\s+(\S+)/;
    #$self->log->debug("OS version: $1");
    return $1;
}

sub _build_arp_table {
    my $self = shift;
    my %arp_table;
    my @data;
    try {
        @data = $self->cmd('get system arp');
    } catch {
        $self->log->error('Error fetching arp table: ', $self->get_error);
        return undef;
    };

    # parse arp table
    # 192.168.1.1 ether 00:b6:aa:f5:bb:6e C eth1
    foreach my $line (@data) {
        if ($line =~ /([0-9\.]+)\s+\d+\s+([a-f0-9:]+)/ ) {
            my ($ip, $mac) = ($1, $2);
            $arp_table{$ip} =  $mac;
        }
    }
    return \%arp_table;
}

sub _build_configuration {
    my $self = shift;
    my ($fh, $filename, $config);
    my $session = $self->session;

   ($fh, $filename) = tempfile();
    try {
        $session->scp_get("sys_config","$filename");
        while(<$fh>){$config .= $_;}
    };
    $self->log->error('Error fetching configuration: $@');
    return $config;
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
