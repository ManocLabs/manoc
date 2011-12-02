package Manoc::Ipaddr;

use Moose;
use Manoc::Utils;

use overload '""' => \&to_string ;

has 'address' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'unpadded_address' => (
  is       => 'ro',
  isa      => 'Str',
  lazy_build => 1,
);

has 'padded_address' => (
  is       => 'ro',
  isa      => 'Str',
  lazy_build => 1,
);

sub _build_padded_address {
 my $self = shift;
 Manoc::Utils::padded_ipaddr($self->address);
}

sub _build_unpadded_address {
 my $self = shift;
 Manoc::Utils::unpadded_ipaddr($self->address);
}

sub to_string {
   return $_[0]->padded_address;
}


1;
