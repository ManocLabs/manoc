package Manoc::IPAddress::IPv4;

use Moose;
use Manoc::Utils::IPAddress qw/padded_ipaddr unpadded_ipaddr/;

use overload ('""'  =>   \&to_string,
	      'lt'  =>   \&less_than,
	      'gt'  =>   \&greater_than,
	      'eq'  =>   \&equal,
	      'le'  =>   \&less_or_equal,
	      'ne'  =>   \&not_equal);

has 'address' => (
    is  => 'rw',
    isa => 'Str',
);

has 'padded' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
    trigger => \&_set_unpadded,
);


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


sub _build_padded {
    my $self = shift;
    return padded_ipaddr( $self->address );
  }

sub _set_unpadded {
   my ($self, $new, $old) = @_;

   $self->address(unpadded_ipaddr( $new ));
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
