package Manoc::ControllerRole::JQDatatable;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

has datatable_search_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    lazy    => 1,
    builder => sub { [  @{ $_[0]->datatable_columns } ] }
);

has datatable_columns => (
    is   => 'rw',
    isa  => 'ArrayRef[Str]',
);

# used add options if needed (JOIN, PREFETCH, ...)
has datatable_search_options => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub get_datatable_resultset {
    my ($self, $c) = @_;

    return $c->stash->{'resultset'};
}

sub datatable_response : Private {
    my ($self, $c) = @_;

    my $rs = $self->get_datatable_resultset($c);
    
    my $col_names      = $self->datatable_columns;
    my $col_formatters = $c->stash->{'col_formatters'} || {};

    my $start = $c->request->param('iDisplayStart') || 0;
    my $size  = $c->request->param('iDisplayLength');
    my $echo  = $c->request->param('sEcho') || 0;

    my $search_filter;

    # create filter (WHERE clause)
    my $search = $c->request->param('sSearch');
    if ($search) {
        $search_filter = [];

        foreach my $col (@{$self->datatable_search_columns}) {
            push @$search_filter, { $col =>  { -like =>  "%$search%" } };

            $c->log->debug("$col like $search");
        }
    }

    my $search_attrs = $self->datatable_search_options;

    # number of rows after filtering (COUNT query)
    my $total_rows = $rs->search($search_filter, $search_attrs)->count();

    # paging (LIMIT clause)
    if ($size) {
        my $page = $size > 0 ? ($start+1) / $size : 1;
        $page == int($page) or $page = int($page) + 1;

        $search_attrs->{page} = $page;
        $search_attrs->{rows} = $size;
        $c->log->debug("page = $page size=$size");
    }

    # sorting (ORDER BY clause)
    my $n_sort_cols = $c->request->param('iSortingCols');
    if ( defined($n_sort_cols) && $n_sort_cols > 0) {
        my @cols;
        foreach my $i (0 .. $n_sort_cols - 1) {
            my $col_idx = $c->request->param("iSortCol_$i");
            my $col = $searchable_columns->[ $col_idx ];

            my $dir = 
              $c->request->param("sSortDir_$i") eq 'desc' ? '-desc' : '-asc';
            push @cols, { $dir => $col };
        }
        $search_attrs->{order_by} = \@cols;
    };

    # search
    my @rows;
    my $search_rs =  $rs->search($search_filter, $search_attrs);
    while (my $item = $search_rs->next) {
        my @row;
        foreach my $name (@$col_names) {
            my $cell = '';

            # defaul accessor is preferred
            $cell = $item->can($name) ? $item->$name : $item->get_column($name);

            my $f = $col_formatters->{$name};
            $f and $cell = $f->($c, $cell, $item);
            push @row, $cell;
        }
        push @rows, \@row;
    }

    my $data = {
        aaData => \@rows, 
        sEcho  => int($echo),
        iTotalRecords => $total_rows,
        iTotalDisplayRecords => $total_rows,
    };

    $c->stash('json_data' => $data);
    $c->forward('View::JSON');
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
