# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::IPAddress::IPv4Network;

use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints;
use Manoc::Utils::IPAddress qw(check_addr netmask2prefix prefix2netmask_i);
use Manoc::IPAddress::IPv4;

use overload (
    '""'   =>   sub { shift->_stringify() },
);

has 'network' => (
    is       => 'ro',
    isa      => 'Manoc::IPAddress::IPv4',
    required => 1,
);

sub _network_i {
    $_[0]->network->numeric();
}

has 'prefix' => (
    is       => 'ro',
    isa      => subtype( 'Int' => where { $_ > 0 && $_ <= 32  } ),
    required => 1,
);

has '_netmask_i' => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_netmask_i',
);

sub _build_netmask_i {
    prefix2netmask_i($_[0]->prefix)
}

has 'netmask' => (
    is       => 'ro',
    isa      => 'Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => 1,
    builder  => '_build_netmask'
);

sub _build_netmask {
    Manoc::IPAddress::IPv4->new(numeric => $_[0]->_netmask_i);
}

has '_broadcast_i' => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_broadcast_i',
);

sub _build_broadcast_i {
    $_[0]->_network_i | ~ $_[0]->_netmask_i;
}

has 'broadcast' => (
    is       => 'ro',
    isa      => 'Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_broadcast',
);

sub _build_broadcast {
    Manoc::IPAddress::IPv4->new(numeric => $_[0]->_broadcast_i);
}

has _first_host_i => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_first_host_i',
);

sub _build_first_host_i {
    $_[0]->_network_i + 1;
}

has first_host => (
    is       => 'ro',
    isa      => 'Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_first_host',
);

sub _build_first_host {
    Manoc::IPAddress::IPv4->new(numeric => $_[0]->_first_host_i);
}

has _last_host_i => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_last_host_i'
);

sub _build_last_host_i {
    $_[0]->_broadcast_i - 1;
}

has last_host => (
    is       => 'ro',
    isa      => 'Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_last_host',
);

sub _build_last_host {
    Manoc::IPAddress::IPv4->new(numeric => $_[0]->_last_host_i);
}

has wildcard => (
    is       => 'ro',
    isa      => 'Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_wildcard'
);

sub _build_wildcard {
    my $self = shift;
    my $prefix = $self->prefix;
    my $addr =  $prefix ? ( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0xFFFFFFFF;
    return Manoc::IPAddress::IPv4->new(numeric => $addr);
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 2) {
	my $network = shift;
	if (!ref($network)) {
	    check_addr($network) and
		$network = Manoc::IPAddress::IPv4->new($network);
	}
	my $prefix = shift;
	if (blessed($prefix) && $prefix->isa('Manoc::IPAddress::IPv4')) {
	    $prefix = $prefix->padded;
	}
	check_addr($prefix) and $prefix = netmask2prefix($prefix);
	return $class->$orig(
	    network => $network,
	    prefix  => $prefix,
	);
    }
    else {
	return $class->$orig(@_);
    }
};

sub _stringify {
    return $_[0]->network->unpadded . "/" . $_[0]->prefix;
}


__PACKAGE__->meta->make_immutable;
1;


# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
