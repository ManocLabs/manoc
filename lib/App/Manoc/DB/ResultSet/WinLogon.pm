package App::Manoc::DB::ResultSet::WinLogon;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

sub register_tuple {
    my $self   = shift;
    my %params = @_;

    my $ipaddr = $params{ipaddr};
    $ipaddr = App::Manoc::IPAddress::IPv4->new( $params{ipaddr} )
        unless blessed( $params{ipaddr} );
    $params{ipaddr} = $ipaddr->padded;

    $self->next::method(%params);
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
