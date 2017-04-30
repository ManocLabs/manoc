# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Controller::Vlan;
use Moose;
use namespace::autoclean;
use App::Manoc::Form::Vlan;

BEGIN { extends 'Catalyst::Controller'; }
with 'App::Manoc::ControllerRole::CommonCRUD' => { -excludes => 'list' };
# TODO
with "App::Manoc::ControllerRole::JSONView";

=head1 NAME

App::Manoc::Controller::Vlan - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for editing VLAN objects.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vlan',
        }
    },
    class                   => 'ManocDB::Vlan',
    form_class              => 'App::Manoc::Form::Vlan',
    json_columns            => [ 'id', 'name', 'description' ],
    enable_permission_check => 1,
    view_object_perm        => undef,
);

=head1 METHODS

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( $c->uri_for_action('vlanrange/list') );
}

=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $range_id = $c->req->query_parameters->{'range'};
    $c->stash( form_defaults => { vlan_range => $range_id } );
};

=head2 get_object_list

=cut

sub get_object_list {
    my ( $self, $c ) = @_;

    my $rs      = $c->stash->{resultset};
    my @objects = $rs->search(
        {},
        {
            prefetch => 'vlan_range',
        }
    );
    return \@objects;
}

=head2 object_delete

=cut

sub object_delete {
    my ( $self, $c ) = @_;
    my $vlan = $c->stash->{'object'};

    if ( $vlan->ip_ranges->count ) {
        $c->flash( error_msg => 'There are subnets in this vlan' );
        return undef;
    }

    $vlan->delete;
}

=head2 get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action("vlanrange/list");
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
