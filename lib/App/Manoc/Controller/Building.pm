package App::Manoc::Controller::Building;
#ABSTRACT: Building Controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::Building;

BEGIN { extends 'App::Manoc::ControllerBase::CRUD'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'building',
        }
    },
    class               => 'ManocDB::Building',
    form_class          => 'App::Manoc::Form::Building',
    view_object_perm    => undef,
    object_list_options => { prefetch => 'racks' },
);

=method delete_object

Override default implementation to warn when building has associated racks or
warehouses.

=cut

sub delete_object {
    my ( $self, $c ) = @_;
    my $building = $c->stash->{'object'};

    if ( $building->warehouses->count ) {
        $c->flash( error_msg => 'Building has associated warehouses and cannot be deleted.' );
        return;
    }

    if ( $building->racks->count ) {
        $c->flash( error_msg => 'Building has associated racks and cannot be deleted.' );
        return;
    }

    $building->delete;
    return 1;
}

=method serialize_object

Override to add rack information

=cut

override 'serialize_object' => sub {
    my ( $self, $c, $building ) = @_;

    my $r = super();
    $r->{racks} = [ map +{ id => $_->id, name => $_->name }, $building->racks ];
    return $r;
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
