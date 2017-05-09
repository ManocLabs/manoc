package App::Manoc::ControllerRole::JQDatatable;
#ABSTRACT: Support for jQuery DataTable

use Moose::Role;

##VERSION

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

=head1 DESCRIPTION

Catalyst controller role for helping managing ajax request for datatables.
See L<http://datatables.net/examples/data_sources/server_side.html>

=cut

has datatable_search_columns => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_datatable_search_columns'
);

has datatable_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

# used add options if needed (JOIN, PREFETCH, ...)
has datatable_search_options => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has datatable_search_callback => ( is => 'rw', );

has datatable_row_callback => ( is => 'rw', );

sub _build_datatable_search_columns {
    my $self = shift;
    $self->datatable_columns or return [];
    return [ @{ $self->datatable_columns } ];
}

=method get_datatable_resultset

Return the resultset to use for datatables.
Defaults to stash->{resultset}

=cut

sub get_datatable_resultset {
    my ( $self, $c ) = @_;

    return $c->stash->{'resultset'};
}

=action datatable_source

View for datatable AJAX data source

=cut

sub datatable_source : Chained('base') : PathPart('datatable_source') : Args(0) {
    my ( $self, $c ) = @_;

    my $start  = $c->request->param('start') || 0;
    my $length = $c->request->param('length');
    my $draw   = $c->request->param('draw') || 0;
    my $search = $c->request->param("search[value]");

    my $rs = $c->stash->{'datatable_resultset'} ||
        $self->get_datatable_resultset($c);

    my $col_names = $c->stash->{'datatable_columns'} ||
        $self->datatable_columns;

    my $search_columns = $c->stash->{'datatable_search_columns'} ||
        $self->datatable_search_columns;

    my $search_callback = $c->stash->{'datatable_search_callback'} ||
        $self->datatable_search_callback;

    my $row_callback = $c->stash->{'datatable_row_callback'} ||
        $self->datatable_row_callback;

    my $total_rows = $rs->count();

    # create  search filter (WHERE clause)
    my $search_filter = {};
    my $search_attrs  = { %{ $self->datatable_search_options } };

    if ($search) {
        $search_filter = [];

        foreach my $col (@$search_columns) {
            push @$search_filter, { $col => { -like => "%$search%" } };
            $c->log->debug("$col like $search");
        }
    }
    if ($search_callback) {
        ( $search_filter, $search_attrs ) =
            $self->$search_callback( $c, $search_filter, $search_attrs );
    }
    my $filtered_rows = $rs->search_rs( $search_filter, $search_attrs )->count();

    # paging (LIMIT clause)
    if ($length) {
        my $page = $length > 0 ? ( $start + 1 ) / $length : 1;
        $page == int($page) or $page = int($page) + 1;

        $search_attrs->{page} = $page;
        $search_attrs->{rows} = $length;
        $c->log->debug("page = $page length = $length");
    }

    # sorting
    my $sort_column_i = $c->request->param('order[0][column]');
    if ( defined($sort_column_i) ) {
        my $column = $col_names->[$sort_column_i];
        my $dir = $c->request->param("order[0][dir]") eq 'desc' ? '-desc' : '-asc';

        $search_attrs->{order_by} = { $dir => $column };
        $c->log->debug("order by $column $dir");
    }

    #  execute the search and populate results
    my $search_rs = $rs->search_rs( $search_filter, $search_attrs );
    my @rows;
    while ( my $item = $search_rs->next ) {
        my $row;
        if ($row_callback) {
            $row = $self->$row_callback( $c, $item );
        }
        else {
            $row = {};

            foreach my $name (@$col_names) {
                # default accessor is preferred
                my $v = $item->can($name) ? $item->$name : $item->get_column($name);
                $row->{$name} = $v;
            }
        }
        push @rows, $row;
    }

    my $data = {
        draw            => int($draw),
        data            => \@rows,
        recordsTotal    => $total_rows,
        recordsFiltered => $filtered_rows,
    };

    $c->stash( 'json_data' => $data );
    $c->forward('View::JSON');
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
