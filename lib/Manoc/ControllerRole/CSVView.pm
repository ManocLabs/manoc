package Manoc::ControllerRole::CSVView;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'object', 'object_list';

has csv_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has csv_column_alias => (
    is  => 'rw',
    isa => 'HashRef[Str]',
    default => sub { {} },
);


=head2 prepare_json_object

Get an hashref from a row.

=cut

sub prepare_csv_object {
    my ( $self, $c, $row ) = @_;

    my $ret = [];
    foreach my $name ( @{ $self->csv_columns } ) {
        # default accessor is preferred
        my $val = $row->can($name) ? $row->$name : $row->get_column($name);
        push @$ret, $val;
    }
    return $ret;
}

=head2 list_csv

=cut

sub list_csv : Chained('object_list') : PathPart('csv') : Args(0) {
    my ( $self, $c ) = @_;

    my $filename = $c->stash->{filename};
    $filename = $c->namespace();
    $filename =~ s|/|_|;

    if ( ! @{$self->csv_columns} ) {
        my @column_names =
            $c->stash->{resultset}->result_source->columns;
        $self->csv_columns(\@column_names);
    }

    my @headers;
    foreach my $col_name ( @{ $self->csv_columns } ) {
        my $name = $self->csv_column_alias->{$col_name} || $col_name;
        push @headers, $name;
    }

    my @data = map { $self->prepare_csv_object( $c, $_ ) } @{ $c->stash->{object_list} };
    $c->stash(
        columns  => \@headers,
        data     => \@data,
        filename => $filename,
        suffix   => '.csv',
        current_view => 'CSV',
    );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
