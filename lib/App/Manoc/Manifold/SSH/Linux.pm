package App::Manoc::Manifold::SSH::Linux;
#ABSTRACT: Manifold for accessing Linux servers/devices

use Moose;

##VERSION

with 'App::Manoc::ManifoldRole::SSH',
    'App::Manoc::ManifoldRole::Base',
    'App::Manoc::ManifoldRole::Host',
    'App::Manoc::ManifoldRole::Hypervisor';

use Try::Tiny;
use App::Manoc::Utils::Units qw(parse_storage_size);

around '_build_username' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() || 'root';
};

has 'use_sudo' => (
    is  => 'rw',
    isa => 'Maybe[Bool]',
);

has 'sudo_password' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    builder => '_build_sudo_password'

);

sub _build_sudo_password {
    my $self = shift;
    return $self->credentials->{password2};
}

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

sub _build_uuid {
    my $self = shift;
    my $r    = $self->dmidecode("system-uuid");
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
        $count++ if $line =~ /processor\s+:\s+(\d+)/;
        $model = $1 if $line =~ /model name\s+:\s+(.+?)$/;
        $freq  = $1 if $line =~ /cpu MHz\s+:\s+(\d+)(\.\d+)=$/;
    }

    return {
        count => $count,
        model => $model,
        freq  => $freq,
    };
}

sub _build_boottime {
    my $self = shift;

    my $data = $self->cmd('cat /proc/uptime');
    chomp($data);
    my ( $seconds, undef ) = split /\s+/, $data;
    return time() - int($seconds);

}

sub _build_name {
    my $self = shift;
    my $r    = $self->cmd('uname -n');
    chomp($r);
    return $r || undef;
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
    my $os = $out[0];
    $os =~ s/\r?\n//o;
    my $ver = $out[1];
    $ver =~ s/\r?\n//o;
    return {
        os  => $os,
        ver => $ver
    };
}

sub _build_os {
    shift->osinfo->{os};
}

sub _build_os_ver {
    shift->osinfo->{ver};
}

sub _build_kernel {
    my $self = shift;

    my $kernel = $self->cmd('uname -s');
    chomp($kernel);
    return $kernel;
}

sub _build_kernel_ver {
    my $self       = shift;
    my $kernel_ver = $self->cmd('uname -r');
    chomp($kernel_ver);
    return $kernel_ver;
}

sub _build_vendor {
    my $self = shift;
    return $self->dmidecode("system-manufacturer");
}

sub _build_model {
    my $self = shift;
    return $self->dmidecode("system-product-name");
}

sub _build_serial {
    my $self = shift;
    return $self->dmidecode("system-serial-number");
}

sub _build_cpu_model {
    my $self = shift;

    return $self->cpuinfo->{model};
}

sub _build_cpu_count {
    my $self = shift;

    return $self->cpuinfo->{count} || 1;
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
        $line =~ /^MemTotal:\s+(\d+)\s+kB$/ and return int( $1 / 1024 );
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
        return;
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

    if ( $self->system('rpm --version') ) {
        $self->log->debug("Using rpm to fetch installed software");

        my @data = $self->cmd('rpm --queryformat "%{NAME} %{VERSION}\n" -qa');
        foreach my $line (@data) {
            chomp($line);
            my ( $pkg, $version ) = split /\s+/, $line;
            push @list, [ $pkg, $version ];
        }
    }
    elsif ( $self->system('dpkg-query --version') ) {
        $self->log->debug("Using dpkg to fetch installed software");

        my @data = $self->cmd("dpkg-query -f '\${binary:Package} \${Version}\n' -W");
        foreach my $line (@data) {
            chomp($line);
            my ( $pkg, $version ) = split /\s+/, $line;
            push @list, [ $pkg, $version ];
        }
    }
    elsif ( $self->system('opkg info opkg') ) {
        $self->log->debug("Using opkg to fetch installed software");

        my @data = $self->cmd('opkg list');
        foreach my $line (@data) {
            chomp($line);
            my ( $pkg, $version ) = split /\s+-\s+/, $line;
            push @list, [ $pkg, $version ];
        }
    }

    return \@list;
}

sub _build_virtual_machines {
    my $self = shift;

    $self->log->warn("Using virsh to get uuid list");
    my @data = $self->root_cmd( 'virsh', 'list', '--uuid' );

    if ( !defined( $data[0] ) ) {
        $self->log->warn("Error using virsh");
        return;
    }

    my @uuids;
    foreach my $line (@data) {
        chomp($line);
        $line or last;

        $line =~ /^([\da-fA-F-]+)$/ and push @uuids, $1;
    }

    my @result;

    foreach my $uuid (@uuids) {
        my $vm_info = {};

        $self->log->debug("Using virsh to get dominfo for $uuid");
        my @data = $self->root_cmd( 'virsh', 'dominfo', $uuid );

        foreach my $line (@data) {
            chomp($line);
            $line or last;

            $line =~ /^([^:]+):\s+(.*)$/o or
                $self->log->warn("cannot parse virsh output line $line"), next;

            my ( $key, $value ) = ( $1, $2 );
            $key eq 'Name' and
                $vm_info->{name} = $value;
            $key eq 'UUID' and
                $vm_info->{uuid} = $value;
            $key eq 'CPU(s)' and
                $vm_info->{vcpus} = $value;
            $key eq 'Max memory' and
                $vm_info->{memsize} = parse_storage_size($value) / ( 1024 * 1024 );
        }
        push @result, $vm_info;

    }
    return \@result;
}

=method dmidecode( $keyworkd )

Call C<dmidecode -s $keyword> as root and return its stdout.

=cut

sub dmidecode {
    my ( $self, $keyword ) = @_;
    my @out = $self->root_cmd( "dmidecode", "-s", $keyword );

    defined( $out[0] ) or return;

    my $ret = undef;
    foreach my $line (@out) {
        next if $line =~ /^#/;
        chomp($line);
        return $line;
    }
    return;
}

=method root_cmd ([$opts, ] @cmds)

Execute command as root. If current user is not root try to use sudo.

=cut

sub root_cmd {
    my $self = shift;

    my $opts = ref( $_[0] ) eq 'ARRAY' ? shift : {};
    my @cmd = @_;

    if ( $self->username ne 'root' ) {
        if ( $self->use_sudo ) {
            my $sudo_passwd = $self->credentials->{password2};

            if ($sudo_passwd) {
                $opts->{stdin_data} = $sudo_passwd;
                $opts->{tty}        = 1;

                @cmd = ( 'sudo', '-k', '-p', '', '--', @cmd );
            }
            else {
                @cmd = ( 'sudo', '--', @cmd );
            }
            $self->log->debug( "using sudo: " . join( ' ', @cmd ) );
        }
        else {
            return;
        }
    }

    return $self->cmd( $opts, @cmd );

}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
