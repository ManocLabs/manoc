package Manoc::ControllerRole::JSONView;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

has json_columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

=head2 prepare_json_object 

Get an hashref from a row.

=cut

sub prepare_json_object {
    my ($self, $row) = @_;

    my $ret = {};
    foreach my $name (@{$self->json_columns}) {
        # default accessor is preferred
        my $val = $row->can($name) ? $row->$name : $row->get_column($name);
        $ret->{$name} = $val;
    }
    return $ret;
}

=head2 view_js

=cut

sub view_js : Chained('object') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    my $r = $self->prepare_json_object($c->stash->{object});
    $c->stash(json_data => $r);
    $c->forward('View::JSON');
}


=head2 list_js

=cut

sub list_js : Chained('object_list') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    my @r = map { $self->prepare_json_object($_) } @{$c->stash->{object_list}};
    $c->stash(json_data => \@r);
    $c->forward('View::JSON');
}



1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
