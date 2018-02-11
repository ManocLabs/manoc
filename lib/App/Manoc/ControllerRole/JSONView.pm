package App::Manoc::ControllerRole::JSONView;
#ABSTRACT: Role for adding JSON support for view and view list

use Moose::Role;
##VERSION

use namespace::autoclean;

use MooseX::MethodAttributes::Role;

requires 'object', 'object_list';

has json_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

# used when json columns are autodiscovered
has json_extra_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

# used when json columns are autodiscovered
has json_filter_columns => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
);

has json_add_object_href => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

=method autodiscover_json_columns

=cut

sub autodiscover_json_columns {
    my ( $self, $c ) = @_;
    my @cols;

    my %filter_columns = map { $_ => 1 } $self->json_filter_columns;

    my $result_source = $c->stash->{resultset}->result_source;
    foreach my $col_name ( $result_source->columns ) {
        next if $filter_columns{$col_name};

        push @cols, $col_name;
    }

    push @cols, @{ $self->json_extra_columns }
        if defined( $self->json_extra_columns );

    $self->json_columns( \@cols );
}

=method prepare_json_object

Get an hashref from a row.

=cut

sub prepare_json_object {
    my ( $self, $c, $row ) = @_;

    my $ret = {};

    if ( !defined( $self->json_columns ) ) {
        $self->autodiscover_json_columns($c);
    }

    foreach my $name ( @{ $self->json_columns } ) {
        # default accessor is preferred
        my $val = $row->can($name) ? $row->$name : $row->get_column($name);
        $ret->{$name} = $val;
    }
    if ( $self->json_add_object_href ) {
        $ret->{href} = $c->uri_for_action( $c->namespace . "/view", [ $row->id ] )->as_string;
    }
    return $ret;
}

=method get_json_object

Call prepare_json_object. Redefine this method for custom serialization.

=cut

sub get_json_object {
    my ( $self, $c, $row ) = shift;
    return $self->prepare_json_object( $c, $row );
}

=action view_js

=cut

sub view_js : Chained('object') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    my $r = $self->prepare_json_object( $c, $c->stash->{object} );
    $c->stash( json_data => $r );
    $c->forward('View::JSON');
}

=action list_js

=cut

sub list_js : Chained('object_list') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    my @r = map { $self->prepare_json_object( $c, $_ ) } @{ $c->stash->{object_list} };
    $c->stash( json_data => \@r );
    $c->forward('View::JSON');
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
