# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::IPBlock;

use strict;
use warnings;

use parent 'Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

sub including_address {
    my ( $self, $ipaddress ) = @_;

    if ( blessed($ipaddress) &&
        $ipaddress->isa('Manoc::IPAddress::IPv4') )
    {
        $ipaddress = $ipaddress->padded;
    }
    return $self->search(
        {
            'from_addr' => { '<=' => $ipaddress },
            'to_addr'   => { '>=' => $ipaddress },
        }
    );
}

sub including_address_ordered {
    shift->including_address(@_)->search(
        {},
        {
            order_by => [ { -desc => 'from_addr' }, { -asc => 'to_addr' } ]
        }
    );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
