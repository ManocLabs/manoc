# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Converter::Base;

use Moose;
use Class::Load;

has 'log' => (
    is       => 'ro',
    required => 1,
);

has 'schema' => (
    is       => 'ro',
    required => 1,
);

sub get_table_name {
    my ($self, $table) = @_;
    return $table;
}

sub upgrade_table {
    my ( $self, $table, $data ) = @_;

    my $method_name = "upgrade_$table";
    return 0 unless $self->can($method_name);

    $self->log->info("Running converter for table $table");
    return $self->$method_name($data);
}

sub before_import_table {
    my ( $self, $table, $data) = @_;

    my $method_name = "before_import_$table";
    return 0 unless $self->can($method_name);

    $self->log->info("Running callback for table $table");
    return $self->$method_name($data);
}

sub after_import_table {
    my ( $self, $table,  $data) = @_;

    my $method_name = "after_import_$table";
    return 0 unless $self->can($method_name);

    $self->log->info("Running callback for table $table");
    return $self->$method_name($data);
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
