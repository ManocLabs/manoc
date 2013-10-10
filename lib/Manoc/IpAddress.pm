package Manoc::IpAddress;

use Moose;
use Manoc::Utils;

use Manoc::IpAddress::Ipv4;
#use Manoc::IpAddress::Ipv6;
use Manoc::Utils; 
use Carp;
use Data::Dumper;

has 'address' => (
    is  => 'rw',
    isa => 'Str',
);

has 'class_spec' => (
    is  => 'ro',
#   isa => 'Str',
    lazy=> 1,
    builder => '_build_class_spec',
);


sub _build_class_spec {
  my $self = shift;
  my $addr = $self->address;
  Manoc::Utils::check_addr($addr)      and return  "Manoc::IpAddress::Ipv4";
  Manoc::Utils::check_ipv6_addr($addr) and return  "Manoc::IpAddress::Ipv6"; 
  carp  "Argument is not a valid Ip address!";
  return;
}

around BUILDARGS => sub {
      my $orig  = shift;
      my $class = shift;

      if ( @_ == 1 && ! ref $_[0] ) {
          return $class->$orig(address => $_[0]);
      }
      else {
          return $class->$orig(@_);
      }
  };

sub BUILD {
      my $self = shift;
      my ($args)=@_;

      defined($self->class_spec) and return bless($self,$self->class_spec);
      
      return ;
}

1;
