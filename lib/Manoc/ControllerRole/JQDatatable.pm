# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ControllerRole::JQDatatable;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

=head1 NAME

Manoc::ControllerRole::JQDatatable - Support for DataTables Table jQuery

=head1 DESCRIPTION

Catalyst controller role for helping managing ajax request for datatables.
See L<http://datatables.net/examples/data_sources/server_side.html>

=cut

die "Not ready for use";

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
    default => sub { {} },
);

sub get_datatable_resultset {
    my ($self, $c) = @_;

    return $c->stash->{'resultset'};
}

sub datatable_response : Private {
    my ($self, $c) = @_;

    my $start = $c->request->param('start') || 0;
    my $size  = $c->request->param('length');
    my $draw  = $c->request->param('draw') || 0;
    my $search = $c->request->param('search');
    
    my $col_names      = $self->datatable_columns;
    my $col_formatters = $c->stash->{'col_formatters'} || {};

    my $rs = $self->get_datatable_resultset($c);
    
    my $search_filter = {};

    # create  search filter (WHERE clause)
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
            my $col = $self->searchable_columns->[ $col_idx ];

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
        my $row;
        
        if ($self->datatable_row_formatter) {
            $row = $self->datatable_row_formatter->($c, $item);
        } else {
            $row = [];
            
            foreach my $name (@$col_names) {
                # defaul accessor is preferred
                my $v = $item->can($name) ? $item->$name : $item->get_column($name);
                push @$row, $v;
            }
        }
        push @rows, $row;
    }

    my $data = {
        draw => int($draw),
        data => \@rows,
        recordsTotal => $total_rows,
        recordsFiltered => $total_rows,
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
