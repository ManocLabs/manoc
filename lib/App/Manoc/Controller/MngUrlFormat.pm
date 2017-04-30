# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Controller::MngUrlFormat;
use Moose;
use namespace::autoclean;

use App::Manoc::Form::MngUrlFormat;

BEGIN { extends 'Catalyst::Controller'; }
with "App::Manoc::ControllerRole::CommonCRUD" => { -excludes => 'view' };

=head1 NAME

App::Manoc::Controller::MngUrl - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'mngurlformat',
        }
    },
    class                   => 'ManocDB::MngUrlFormat',
    form_class              => 'App::Manoc::Form::MngUrlFormat',
    enable_permission_check => 1,
    view_object_perm        => undef,

);

=head1 METHODS

=cut

=head2 delete

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $id = $c->stash->{object_pk};
    if ( $c->model('ManocDB::Device')->search( { mng_url_format => $id } )->count ) {
        $c->flash( error_msg => 'Format is in use. Cannot be deleted.' );
        return undef;
    }

    return $c->stash->{'object'}->delete;
}

=head2 get_delete_failure_url

=cut

sub get_delete_failure_url {
    my ( $self, $c ) = @_;

    my $action = $c->namespace . "/list";
    return $c->uri_for_action($action);
}

1;
