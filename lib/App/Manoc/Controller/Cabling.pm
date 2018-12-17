package App::Manoc::Controller::Cabling;
#ABSTRACT: Cabling Controller

use Moose;

##VERSION

#TODO: if this controller should be used, it's jus for matrix view

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectForm',
    'App::Manoc::ControllerRole::ObjectList',
    'App::Manoc::ControllerRole::ObjectSerializer',
    'App::Manoc::ControllerRole::JSONEdit',
    'App::Manoc::ControllerRole::JSONView',
    'App::Manoc::ControllerRole::CSVView';

use App::Manoc::Form::Cabling;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'cabling',
        }
    },
    class               => 'ManocDB::CablingMatrix',
    form_class          => 'App::Manoc::Form::Cabling',
    view_object_perm    => undef,
    object_list_options => { prefetch => [ 'interface2', 'serverhw_nic' ] },
);

=action list

Display a list of items.

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

}

=action list_js

=cut

sub list_js : Chained('object_list') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('object_list_js');
}

=method prepare_csv_objects

Custom serialization for CSV export

=cut

sub prepare_csv_objects {
    my ( $self, $c, $rows ) = @_;

    my $csv_columns =
        [ "Source device", "Source interface", "Destination target", "Destination interface", ];
    $c->stash( serialized_columns => $csv_columns );

    my @data;
    foreach my $cabling (@$rows) {
        my $row = [ $cabling->interface1->device->label, $cabling->interface1->label, ];
        if ( $cabling->interface2 ) {
            push @$row, $cabling->interface2->device->label, $cabling->interface2->label;
        }
        elsif ( $cabling->serverhw_nic ) {
            my $serverhw = $cabling->serverhw_nic->serverhw;
            if ( $serverhw->server ) {
                push @$row, $serverhw->server->label;
            }
            else {
                push @$row, $serverhw->label;
            }
            push @$row, $cabling->serverhw_nic->label;
        }

        push @data, $row;
    }

    return \@data;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
