package App::Manoc::IPAddress::IPv4;
#ABSTRACT: IPv4 Addresses

use Moose;

##VERSION

=head1 DESCRIPTION

A class for IPv4 addresses. Supports padding, unpadding,
stringification and comparison operators.

=head1 SYNOSPIS

  my $addr = App::Manoc::IPAddress::IPv4->new('10.1.100.1');


  $addr->padded; # '010.001.100.001'
  $addr->unpadded; # '10.1.100.1'

  "$addr" eq '10.1.100.1'; # true

  $addr > App::Manoc::IPAddress::IPv4->new('2.1.1.1'); # also true

=cut

use namespace::autoclean;

use App::Manoc::Utils::IPAddress qw(ip2int int2ip padded_ipaddr check_addr);

use overload (
    '""'  => sub { shift->_stringify() },
    'cmp' => \&_cmp_op,
    '<=>' => \&_cmp_op,
);

=attr numeric

Address integer representation.

=cut

has 'numeric' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=attr padded

=cut

has 'padded' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_padded'
);

=attr unpadded
=cut

has 'unpadded' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_unpadded'
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    return unless $_[0];

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( numeric => ip2int( $_[0] ) );
    }
    else {
        return $class->$orig(@_);
    }
};

=method address

Return the address in unpadded form. Automatically called by stringification.

=cut

sub address {
    return $_[0]->unpadded;
}

sub _build_padded {
    padded_ipaddr( $_[0]->unpadded );
}

sub _build_unpadded {
    int2ip( $_[0]->numeric );
}

sub _stringify {
    return $_[0]->unpadded;
}

sub _cmp_op {
    my ( $first, $second ) = @_;
    if ( blessed($second) && $second->isa("App::Manoc::IPAddress::IPv4") ) {
        return $first->numeric <=> $second->numeric;
    }
    check_addr("$second") and
        return ( $first->padded cmp padded_ipaddr("$second") );
    return -1;
}

__PACKAGE__->meta->make_immutable;
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
