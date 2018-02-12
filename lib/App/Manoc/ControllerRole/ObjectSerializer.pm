package App::Manoc::ControllerRole::ObjectSerializer;
#ABSTRACT:  Role for controllers accessing resultset

use Moose::Role;

##VERSION

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

=head1 NAME

App::Manoc::ControllerRole::ResultSet

=head1 DESCRIPTION

This is a role providing support function for controllers which serialize a resultset.

=cut

# columns to be serialized
has serialize_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

# used when columns to be serialized are autodiscovered
has serialize_extra_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

# used when columns to be serialized are autodiscovered
has serialize_exclude_columns => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
);

has serialize_add_object_href => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

=method autodiscover_serialize_columns

=cut

sub autodiscover_serialize_columns : Private {
    my ( $self, $c ) = @_;
    my @cols;

    my $result_source = $c->stash->{resultset}->result_source;

    my $serialize_exclude_columns =
        exists( $c->stash->{serialize_exclude_columns} ) ?
        $c->stash->{serialize_exclude_columns} :
        $self->serialize_exclude_columns;

    my $serialize_extra_columns =
        exists( $c->stash->{serialize_extra_columns} ) ? $c->stash->{serialize_extra_columns} :
        $self->serialize_extra_columns;

    my %filter_columns = map { $_ => 1 } $serialize_exclude_columns;

    foreach my $col_name ( $result_source->columns ) {
        next if $filter_columns{$col_name};

        push @cols, $col_name;
    }

    push @cols, @{$serialize_extra_columns}
        if defined($serialize_extra_columns);

    return \@cols;
}

=method serialize_object ( $c, $row)

Get an hashref from a row.

=cut

sub serialize_object {
    my ( $self, $c, $row ) = @_;

    my $ret = $self->serialize_objects( $c, [$row] );
    return ref($ret) eq 'ARRAY' ? $ret->[0] : undef;
}

=method serialize_objects ( $c, \@rows)

Get an hashref from a row.

=cut

sub serialize_objects {
    my ( $self, $c, $rows ) = @_;

    my @serialized_objects;

    my $serialize_columns =
        exists( $c->stash->{serialize_columns} ) ? $c->stash->{serialize_columns} :
        $self->serialize_columns;

    $serialize_columns ||= $self->autodiscover_serialize_columns($c);

    my $serialize_add_object_href =
        exists( $c->stash->{serialize_add_object_href} ) ?
        $c->stash->{serialize_add_object_href} :
        $self->serialize_add_object_href;

    foreach my $row (@$rows) {
        my $ret = {};

        foreach my $name (@$serialize_columns) {
            # default accessor is preferred
            my $val = $row->can($name) ? $row->$name : $row->get_column($name);
            $ret->{$name} = $val;
        }
        if ( $row->can('label') ) {
            $ret->{label} = $row->label;
        }
        if ($serialize_add_object_href) {
            $ret->{href} = $c->manoc_uri_for_object($row);
        }

        push @serialized_objects, $ret;
    }

    return \@serialized_objects;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
