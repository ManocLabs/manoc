package App::Manoc::ControllerRole::CSVView;

use Moose::Role;

##VERSION

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'object_list', 'serialize_objects';

has csv_columns => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has csv_column_alias => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { {} },
);

=method prepare_csv_objects

Call serialize_objects. Redefine this method for custom serialization.

=cut

sub prepare_csv_objects {
    my ( $self, $c, $rows ) = @_;

    my $csv_columns = $self->csv_columns;
    @$csv_columns and $c->stash( serialize_columns => $csv_columns );

    return $self->serialize_objects( $c, $rows );
}

=action list_csv

View chained to C<object_list> to generate a CSV file.
File name defaults to namespace and can be overridden via filename in stash.

=cut

sub list_csv : Chained('object_list') : PathPart('csv') : Args(0) {
    my ( $self, $c ) = @_;

    my $filename = $c->stash->{filename};
    $filename = $c->namespace();
    $filename =~ s|/|_|;

    my $data = $self->prepare_csv_objects( $c, $c->stash->{object_list} );

    my @headers;
    foreach my $col_name ( @{ $c->stash->{serialized_columns} } ) {
        my $name = $self->csv_column_alias->{$col_name} || $col_name;
        push @headers, $name;
    }

    $c->stash(
        columns      => \@headers,
        data         => $data,
        filename     => $filename,
        suffix       => '.csv',
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
