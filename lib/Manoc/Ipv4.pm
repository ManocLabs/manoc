package Manoc::Ipv4;

use Moose;
use Manoc::Utils;

use overload '""' => \&to_string ;

has 'addr' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'padded' => (
  is       => 'ro',
  isa      => 'Str',
  lazy_build => 1,
);

sub _build_padded {
 my $self = shift;
 Manoc::Utils::padded_ipaddr($self->addr);
}

sub to_string {
   return $_[0]->padded;
}


1;
