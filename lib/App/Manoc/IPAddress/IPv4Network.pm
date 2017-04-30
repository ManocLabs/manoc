package App::Manoc::IPAddress::IPv4Network;

use Moose;

##VERSION

use namespace::autoclean;

use Moose::Util::TypeConstraints;
use App::Manoc::Utils::IPAddress qw(check_addr netmask2prefix prefix2netmask_i);
use App::Manoc::IPAddress::IPv4;

use overload ( '""' => sub { shift->_stringify() }, );

has 'address' => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    required => 1,
    writer   => '_set_address',
);

sub _address_i {
    $_[0]->address->numeric();
}

has 'prefix' => (
    is       => 'ro',
    isa      => subtype( 'Int' => where { $_ >= 0 && $_ <= 32 } ),
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
    prefix2netmask_i( $_[0]->prefix );
}

has 'netmask' => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => 1,
    builder  => '_build_netmask'
);

sub _build_netmask {
    App::Manoc::IPAddress::IPv4->new( numeric => $_[0]->_netmask_i );
}

has '_broadcast_i' => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_broadcast_i',
);

sub _build_broadcast_i {
    $_[0]->_address_i | ~$_[0]->_netmask_i;
}

has 'broadcast' => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_broadcast',
);

sub _build_broadcast {
    App::Manoc::IPAddress::IPv4->new( numeric => $_[0]->_broadcast_i );
}

has _first_host_i => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_first_host_i',
);

sub _build_first_host_i {
    $_[0]->_address_i + 1;
}

has first_host => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_first_host',
);

sub _build_first_host {
    App::Manoc::IPAddress::IPv4->new( numeric => $_[0]->_first_host_i );
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
    isa      => 'App::Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_last_host',
);

sub _build_last_host {
    App::Manoc::IPAddress::IPv4->new( numeric => $_[0]->_last_host_i );
}

has wildcard => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_wildcard'
);

sub _build_wildcard {
    my $self   = shift;
    my $prefix = $self->prefix;
    my $addr   = $prefix ? ( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0xFFFFFFFF;
    return App::Manoc::IPAddress::IPv4->new( numeric => $addr );
}

has num_hosts => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_num_hosts'
);

sub _build_num_hosts {
    return $_[0]->_last_host_i - $_[0]->_first_host_i + 1;
}

sub contains_address {
    my ( $self, $address ) = @_;

    blessed($address) and
        $address->isa('App::Manoc::IPAddress::IPv4') and
        $address = $address->numeric;

    return ( $address & $self->_netmask_i ) == $self->_address_i;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 2 ) {
        my $address = shift;
        if ( !ref($address) ) {
            check_addr($address) and
                $address = App::Manoc::IPAddress::IPv4->new($address);
        }
        my $prefix = shift;
        if ( blessed($prefix) && $prefix->isa('App::Manoc::IPAddress::IPv4') ) {
            $prefix = $prefix->padded;
        }
        check_addr($prefix) and $prefix = netmask2prefix($prefix);
        return $class->$orig(
            address => $address,
            prefix  => $prefix,
        );
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;

    my $address_i  = $self->address->numeric;
    my $prefix     = $self->prefix;
    my $wildcard_i = $prefix ? ( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0xFFFFFFFF;

    if ( ( $address_i & $wildcard_i ) != 0 ) {
        my $new_address_i = $address_i & prefix2netmask_i($prefix);
        $self->_set_address( App::Manoc::IPAddress::IPv4->new( numeric => $new_address_i ) );
    }
}

sub _stringify {
    my $self = shift;
    return $self->address->unpadded . "/" . $self->prefix;
}

__PACKAGE__->meta->make_immutable;
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
