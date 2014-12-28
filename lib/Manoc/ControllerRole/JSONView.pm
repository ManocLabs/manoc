package Manoc::ControllerRole::JSONView;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'fetch_list';
requires 'prepare_json_object';

=head2 view_js

=cut

sub view_js : Chained('object') : PathPart('view/js') : Args(0) {
    my ( $self, $c ) = @_;
    
    my $r = $self->prepare_json_object($c->stash->{object});

    $c->stash(json_data => $r);
    $c->forward('View::JSON');
}


=head2 list_js

=cut

sub list_js : Chained('base') : PathPart('list/js') : Args(0) {
   my ( $self, $c ) = @_;

   $c->forward('fetch_list');
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
