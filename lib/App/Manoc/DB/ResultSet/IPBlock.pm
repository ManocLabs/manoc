package App::Manoc::DB::ResultSet::IPBlock;
#ABSTRACT: ResultSet class for IPBlock
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

=method including_address( $ipaddress )

Return a resultset for all IPBlocks containing C<$ipaddress>.

=cut

sub including_address {
    my ( $self, $ipaddress ) = @_;

    if ( blessed($ipaddress) &&
        $ipaddress->isa('App::Manoc::IPAddress::IPv4') )
    {
        $ipaddress = $ipaddress->padded;
    }
    my $rs = $self->search(
        {
            'from_addr' => { '<=' => $ipaddress },
            'to_addr'   => { '>=' => $ipaddress },
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method including_address_ordered

Same as including_address but ordered by lower bound of the block

=cut

sub including_address_ordered {
    my $rs = shift->including_address(@_)->search(
        {},
        {
            order_by => [ { -desc => 'from_addr' }, { -asc => 'to_addr' } ]
        }
    );
    return wantarray ? $rs->all : $rs;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
