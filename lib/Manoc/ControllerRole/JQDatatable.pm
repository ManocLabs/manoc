package Janine::ControllerRole::JQDatatable;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

sub datatable_response : Private {
    my ($self, $c) = @_;

    my $rs = $c->stash->{'resultset'};
    my $search_options = $c->stash->{'resultset_search_opt'};
    my $col_names = $c->stash->{'col_names'};
    my $col_formatters = $c->stash->{'col_formatters'} || {};

    my $searchable_columns =
      $c->stash->{'col_searchable'} || [ @$col_names ];

    my $start = $c->request->param('iDisplayStart') || 0;
    my $size  = $c->request->param('iDisplayLength');
    my $echo  = $c->request->param('sEcho') || 0;

    my $search_attrs = {};
    my $search_filter;

    # create filter (WHERE clause)
    my $search = $c->request->param('sSearch');
    if ($search) {
        $search_filter = [];

        foreach my $col (@$searchable_columns) {
            push @$search_filter, { $col =>  { -like =>  "%$search%" } };

            $c->log->debug("$col like $search");
        }
    }

    # add options if needed (JOIN, PREFETCH, ...)
    if ($search_options) {
        while ( my ($k, $v) = each(%$search_options) ) {
            $search_attrs->{$k} = $v;
        }
    }

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

    # search!!!
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
