package App::Manoc::Controller::Rack;
#ABSTRACT: Rack controller
use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with
    'App::Manoc::ControllerRole::CommonCRUD' => { -excludes => 'delete_object' },
    'App::Manoc::ControllerRole::JSONView'   => { -excludes => 'get_json_object', };

use App::Manoc::Form::Rack;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'rack',
        }
    },
    class               => 'ManocDB::Rack',
    form_class          => 'App::Manoc::Form::Rack',
    view_object_perm    => undef,
    json_columns        => [ 'id', 'name' ],
    object_list_options => {
        prefetch => 'building',
        join     => 'building',
        order_by => 'me.name',
    }
);

=action create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $building_id = $c->req->query_parameters->{'building'};
    $building_id and $c->log->debug("new rack in $building_id");
    $c->stash( form_defaults => { building => $building_id } );
};

=method delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $rack = $c->stash->{'object'};

    if ( $rack->hwassets->count ) {
        $c->flash( error_msg => "Rack contains hardware assets. Cannot be deleted." );
        return;
    }
    if ( $rack->devices->count ) {
        $c->flash( error_msg => "Rack has associated devices. Cannot be deleted." );
        return;
    }

    return $rack->delete;
}

=method get_json_object

=cut

sub get_json_object {
    my ( $self, $c, $rack ) = @_;

    my $r = $self->prepare_json_object( $c, $rack );
    $r->{building} = {
        id   => $rack->building->id,
        name => $rack->building->name,
    };
    $r->{devices} = [ map +{ id => $_->id, name => $_->name }, $rack->devices ];
    return $r;
}

__PACKAGE__->meta->make_immutable;

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
