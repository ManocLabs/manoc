package Manoc::IpAddress::Ipv4;

use Moose;
use Manoc::Utils;
extends 'Manoc::IpAddress';

use overload ('""'  =>   \&to_string,
	      'lt'  =>   \&less_than,
	      'gt'  =>   \&greater_than,
	      'eq'  =>   \&equal,
	      'le'  =>   \&less_or_equal, );

has 'padded' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
    trigger => \&_set_unpadded,
);

sub _build_padded {
    my $self = shift;
    return Manoc::Utils::padded_ipaddr( $self->address );
  }

sub _set_unpadded {
   my ($self, $new, $old) = @_;

   $self->address(Manoc::Utils::unpadded_ipaddr( $new ));
}

sub to_string {
    return $_[0]->padded;
}

sub less_than {
  my ($first, $second) = @_;
  return unless defined $second;
  $second = $second->padded if(ref $second);
  return $first->padded lt $second;
}

sub less_or_equal {
  my ($first, $second) = @_;
  return unless defined $second;
  $second = $second->padded if(ref $second);
  return $first->padded le $second;
}

sub greater_than {
  my ($first, $second) = @_;
  return unless defined $second;
  $second = $second->padded if(ref $second);
  return $first->padded gt $second;
}

sub equal {
 my ($first, $second) = @_;
  return unless defined $second;
 
 $first  = $first->padded  if(defined($first)  and ref $first);
 $second = $second->padded if(defined($second) and ref $second);

  return $first eq $second;
}


1;
