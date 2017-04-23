package App::Manoc::ControllerRole::ObjectList;
#ABSTRACT: Role for controllers accessing a list of results
use Moose::Role;

##VERSION

use namespace::autoclean;

use MooseX::MethodAttributes::Role;

=head1 DESCRIPTION

This is a base role for Manoc controllers which manage a list of rows from
a resultset.

=head1 SYNOPSYS

  package App::Manoc::Controller::Artist;

  use Moose;
  extends "Catalyst::Controller";
  with "App::Manoc::ControllerRole::Object";

  __PACKAGE__->config(
      # define PathPart
      action => {
          setup => {
              PathPart => 'artist',
          }
      },
      class      => 'ManocDB::Artist',

      # artists can be filtered by name using query parameters
      object_list_filter_columns => [ 'name' ],

      # prefetch cds
      object_list_options => { prefetch => 'cds' },
  );

  # manages /artist/
  sub list : Chained('object_list') : PathPart('') : Args(0) {
     my ( $self, $c ) = @_;

     # render with default template
     # objects are stored in $c->{object_list}
  }

=action object_list

Load the list of objects from the resultset into the stash. Chained to base.
This is the point for chaining all actions using the list of object.

Objects are fetched by C<get_object_list> and stored in $c->stash->{object_list}.

=cut

requires 'base';

=attr object_list_filter_columns

=cut

has object_list_filter_columns => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
);

=attr object_list_options

Options for the DBIc search in C<get_object_list>.
Can be overridden by $c->stash->{object_list_options}.

=cut

has object_list_options => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

=action object_list

Populate object_list in stash using get_object_list method.

=cut

sub object_list : Chained('base') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( object_list => $self->get_object_list($c) );
}

=method get_object_list

Search in $c->stash->{resultset} using the filter returned by
C<get_object_list_filter> and the options in $c->stash->{object_list_options}
or object_list_options.

=cut

sub get_object_list {
    my ( $self, $c ) = @_;

    my $rs      = $c->stash->{resultset};
    my $filter  = $self->get_object_list_filter($c);
    my $options = $c->stash->{object_list_options} || $self->object_list_options;
    return [ $rs->search( $filter, $options )->all ];
}

=method get_object_list_filter

=cut

sub get_object_list_filter {
    my ( $self, $c ) = @_;

    my %filter;

    my $qp = $c->req->query_parameters;
    foreach my $col ( @{ $self->object_list_filter_columns } ) {
        my $param = $qp->{$col};
        defined($param) or next;
        ref($param) eq "ARRAY" and next;
        $filter{$col} = $param;
        $c->log->debug("filter object list $col = $param") if $c->debug;
    }

    return \%filter;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
