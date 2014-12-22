package Manoc::IpAddress::Ipv4;

use Moose;
use Manoc::Utils;
use Scalar::Util;
extends 'Manoc::IpAddress';

use overload ('""'  =>   \&to_string,
	      'lt'  =>   \&less_than,
	      'gt'  =>   \&greater_than,
	      'eq'  =>   \&equal,
	      'le'  =>   \&less_or_equal,
	      'ne'  =>   \&not_equal);

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


# WARNING: used by comparison operators
sub to_string {
    return $_[0]->padded;
}

sub less_than {
  my ($first, $second) = @_;
  return unless defined $second;
  return "$first" lt "$second";
}

sub less_or_equal {
    my ($first, $second) = @_;
    defined $second or return;
    return "$first" le "$second";
}

sub greater_than {
    my ($first, $second) = @_;
    defined $second or return 1;
    return "$first" gt "$second";
}

sub not_equal {
    my ($first, $second) = @_;
    return !equal($first, $second);
}

sub equal {
    my ($first, $second) = @_;
    return 0 unless defined $second;
    return "$first" eq "$second";
}


1;
