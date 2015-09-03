# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::IPAddress::IPv4;

use Moose;
use namespace::autoclean;

use Manoc::Utils::IPAddress qw(ip2int int2ip padded_ipaddr);


use overload (
    '""'   =>   sub { shift->_stringify() },
    'cmp'  =>   \&_cmp_op,
    '<=>'  =>   \&_cmp_op,
);


has 'numeric' => (
    is      => 'ro',
    isa     => 'Int',
    required => 1,
);

has 'padded' => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy       => 1,
    builder    => '_build_padded'
);

has 'unpadded' => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy       => 1,
    builder    => '_build_unpadded'
);


around BUILDARGS => sub {
      my $orig  = shift;
      my $class = shift;

      if ( @_ == 1 && ! ref $_[0] ) {
          return $class->$orig(numeric => ip2int($_[0]));
      }
      else {
          return $class->$orig(@_);
      }
  };

sub address {
    return $_[0]->unpadded;
}

sub _build_padded {
    padded_ipaddr($_[0]->unpadded)
}

sub _build_unpadded {
    int2ip($_[0]->numeric)
}

sub _stringify {
    return $_[0]->unpadded;
}

sub _cmp_op {
    my ($first, $second) = @_;
    if (blessed($second) && $second->isa("Manoc::IPAddress::IPv4")) {
	return $first->numeric <=> $second->numeric;
    }
    check_addr("$second") and
        return  ( $first->padded cmp padded_ipaddr("$second") );
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
