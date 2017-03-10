# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Manifold::SSH::Linux;
use Moose;
with 'Manoc::ManifoldRole::SSH';

with 'Manoc::ManifoldRole::Base';
with 'Manoc::ManifoldRole::Host';

use Try::Tiny;

around '_build_username' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() || 'root';
};

has has_perl => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_build_has_perl',
);

sub _build_has_perl {
    my $self = shift;

    if ( $self->session->test('perl -e "1;"') ) {
        return 1;
    }
    return 0;
}


sub _build_boottime {
    my $self = shift;

    my $data = $self->cmd_online('cat /proc/uptime');
    my ( $seconds, undef ) = split /\s+/, $data;
    return time() - int($seconds);

}

sub _build_name {
    my $self = shift;
    return $self->cmd_online('uname -n');
}

has osinfo => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    builder => '_build_osinfo',
);

sub _build_osinfo {
    my $self = shift;

    my $os_script = <<'EOS'
if test -x lsb_release; then
  lsb_release -si
  lsb_release -sr
elif test -e '/etc/debian_version'; then
  echo 'Debian'
  cat /etc/debian_version
elif test -e '/etc/gentoo-release'; then
  echo 'Gentoo'
elif test -e '/etc/fedora-release'; then
  echo 'Fedora'
elif test -e '/etc/centos-release'; then
  echo 'CentOs'
  sed /etc/centos-release -ne 's/.* \([0-9]\{1,\}\.[0-9]\{1,\}\).*/\1/p'
elif test -e '/etc/redhat-release'; then
  echo 'RedHat'
  sed /etc/redhat-release -ne 's/.* \([0-9]\{1,\}\.[0-9]\{1,\}\).*/\1/p'
elif test -e '/etc/SuSE-release'; then
  echo 'SuSE'
elif test -e '/etc/openwrt_version'; then
  . /etc/openwrt_release
  echo $DISTRIB_ID
  echo $DISTRIB_RELEASE
fi
EOS
        ;

    my @out = $self->cmd( { stdin_data => $os_script }, "sh" );
    my $os  = $out[0]; $os  =~ s/\r?\n//o;
    my $ver = $out[1]; $ver =~ s/\r?\n//o;
    return {
        os  => $os,
        ver => $ver
    }
}

sub _build_os {
    shift->osinfo->{os};
}

sub _build_os_ver {
    shift->osinfo->{ver};
}

sub _build_kernel {
    my $self = shift;

    return $self->cmd_online('uname -s');
}

sub _build_kernel_ver {
    my $self = shift;

    return $self->cmd_online('uname -r');
}

sub _build_model {
    my $self = shift;

    my $model = $self->cmd_online("/bin/uname -m");
    return $model;
}

sub _build_serial { undef }

sub _build_vendor { undef }

sub _build_cpu_count {
    my $self = shift;

    return $self->cpuinfo->{count} || 1;
}

sub _build_cpu_model {
    my $self = shift;

    return $self->cpuinfo->{model};
}

has cpuinfo => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_cpuinfo'
);

sub _build_cpuinfo {
    my $self = shift;

    my @data;
    try {
        @data = $self->cmd('/bin/cat /proc/cpuinfo');
    }
    catch {
        $self->log->error( 'Error fetching cpuinfo: ', $self->get_error );
    };

    my $count = 0;
    my $model = 'Unknwown';
    my $freq  = 0;

    foreach my $line (@data) {
        $count++     if $line =~ /processor\s+:\s+(\d+)/;
        $model = $1  if $line =~ /model name\s+:\s+(.+?)$/;
        $freq  = $1  if $line =~ /cpu MHz\s+:\s+(\d+)(\.\d+)=$/
    }

    return {
        count => $count,
        model => $model,
        freq  => $freq,
    };
}

sub _build_ram_memory {
    my $self = shift;

    my @data;
    try {
        @data = $self->cmd('/bin/cat /proc/meminfo');
    }
    catch {
        $self->log->error( 'Error fetching cpuinfo: ', $self->get_error );
    };

    foreach my $line (@data) {
        $line =~ /^MemTotal:\s+(\d+)\s+kB$/ and return int($1/1024);
    }

    return 0;
}

sub _build_arp_table {
    my $self = shift;

    my %arp_table;
    my @data;
    try {
        @data = $self->cmd('/sbin/arp -n');

    }
    catch {
        $self->log->error( 'Error fetching arp table: ', $self->get_error );
        return undef;
    };

    # parse arp table
    # 192.168.1.1 ether 00:b6:aa:f5:bb:6e C eth1
    foreach my $line (@data) {
        if ( $line =~ /([0-9\.]+)\s+ether\s+([a-f0-9:]+)/ ) {
            my ( $ip, $mac ) = ( $1, $2 );
            $arp_table{$ip} = $mac;
        }
    }
    return \%arp_table;
}


sub _build_installed_sw {
    my $self = shift;

    my @list;

    if ( $self->session->test('rpm --version') ) {
        $self->log->debug("Using rpm to fetch installed software");

        my @data = $self->cmd('rpm --queryformat "%{NAME} %{VERSION}\n" -qa');
        foreach my $line (@data) {
            chomp($line);
            my ($pkg, $version) = split /\s+/, $line;
            push @list, [ $pkg, $version ];
        }
    } elsif ( $self->session->test('opkg info opkg') ) {
        $self->log->debug("Using opkg to fetch installed software");

        my @data = $self->cmd('opkg list');
        foreach my $line (@data) {
            chomp($line);
            my ($pkg, $version) = split /\s+-\s+/, $line;
            push @list, [ $pkg, $version ];
        }
    }

    return \@list;
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
