package App::Manoc::DB::ResultSet::WinHostname;
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

use Scalar::Util qw(blessed);
use App::Manoc::DB::Search::Result::Hostname;

=method register_tuple( %params )

Overridden in order to convert $params{ipaddr} to
L<App::Manoc::IPAddress::IPv4> if needed.

=cut

sub register_tuple {
    my $self   = shift;
    my %params = @_;

    my $ipaddr = $params{ipaddr};
    $ipaddr = App::Manoc::IPAddress::IPv4->new( $params{ipaddr} )
        unless blessed( $params{ipaddr} );
    $params{ipaddr} = $ipaddr->padded;

    $self->next::method(%params);
}

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $type    = $query->query_type;
    my $pattern = $query->sql_pattern;

    if ( $type eq 'logon' ) {

        my $rs = $self->search(
            { name => { '-like' => $pattern } },
            {
                order_by => 'name',
                group_by => 'ipaddr',
            }
        );

        while ( my $e = $rs->next ) {
            my $item = App::Manoc::DB::Search::Result::Hostname->new(
                ipaddress => $e->ipaddr,
                hostname  => $e->name,
                match     => $e->name,
            );
            $result->add_item($item);
        }
    }
}

=head1 SEE ALSO

L<DBIx::Class::ResultSet>

=cut

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
