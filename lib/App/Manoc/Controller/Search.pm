package App::Manoc::Controller::Search;
#ABSTRACT: Search controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Utils::Datetime qw(str2seconds);

BEGIN { extends 'Catalyst::Controller'; }

=action index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    my $q        = $c->request->param('q') || '';
    my $button   = $c->request->param('submit');
    my $advanced = $c->request->param('advanced') || 0;
    my $limit    = $advanced ? $c->request->param('limit') : undef;
    my $type     = $advanced ? $c->request->param('type')  : undef;

    my @search_types = (
        [ 'ipaddr',    'IP' ],
        [ 'macaddr',   'MAC' ],
        [ 'inventory', 'Inventory' ],
        [ 'logon',     'Logon' ],
        [ 'note',      'Notes' ],
    );

    my $redirectable_types = {
        device   => '/device/view',
        rack     => '/rack/view',
        building => '/building/view',
        server   => '/server/view',
        hwasset  => '/hwasset/view',
    };

    if ( $q =~ /\S/ ) {
        $q =~ s/^\s+//o;
        $q =~ s/\s+$//o;

        my %query_param;
        $limit and $query_param{limit} = str2seconds($limit);
        $type  and $query_param{type}  = $type;

        my $result = $c->model('ManocDB')->search( $q, \%query_param );
        $c->stash( result => $result );

        my $query = $result->query;
        my $type  = $query->query_type;

        if ( !$advanced && $redirectable_types->{$type} ) {
            # search for an exact match and redirect if found
            my $selected_item;

            foreach my $item ( @{ $result->items } ) {
                if ( $item->can('items') ) {
                    my $item2 = $item->items->[0];
                    if ( lc( $item2->match ) eq lc( $query->query_as_word ) ) {
                        $selected_item = $item2;
                        last;
                    }
                }
                else {
                    if ( lc( $item->match ) eq lc( $query->query_as_word ) ) {
                        $selected_item = $item;
                        last;
                    }
                }
            }
            if ($selected_item) {
                $c->response->redirect(
                    $c->uri_for_action(
                        $redirectable_types->{$type},
                        [ $selected_item->row->id ]
                    )
                );
                $c->detach();
            }
        }
    }

    $c->stash(
        fif => {
            'q'      => $q,
            limit    => $limit,
            type     => $c->request->param('type') || 'ipaddr',
            advanced => $advanced,
        }
    );
    $c->stash( search_types => \@search_types );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
