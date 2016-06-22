# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::HWAsset;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'Manoc::ControllerRole::CommonCRUD';
with 'Manoc::ControllerRole::JSONView';
with 'Manoc::ControllerRole::JQDatatable';

use Manoc::DB::Result::HWAsset;

use Manoc::Form::HWAsset;

=head1 NAME

Manoc::Controller::HWAsset - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'hwasset',
        }
    },
    class      => 'ManocDB::HWAsset',
    form_class => 'Manoc::Form::HWAsset',

    json_columns => [ qw(serial vendor model inventory rack_id rack_level building room)],

    datatable_row_callback => 'datatable_row',
);

=head1 METHODS

=cut

sub get_form_process_params {
    my $self = shift;
    my $c    = shift;

    my %params = @_;

    my $qp =  $c->req->query_parameters;

    if ( my $type = $qp->{type} ) {
        # check if is a valid type before using it
        $Manoc::DB::Result::HWAsset::TYPE{$type} and
            $params{preset_type} = $type;
    }
    $qp->{building} and $params{defaults}->{building} = $qp->{'building'};

    return %params;
}


sub datatable_row {
    my ($self, $c, $row) = @_;

    return {
        inventory => $row->inventory,
        type      => $row->type,
        vendor    => $row->vendor,
        model     => $row->model,
        serial    => $row->serial,
        in_warehouse => $row->in_warehouse,
        location  => $row->location,
        link      => $c->uri_for_action('hwasset/view', [ $row->id ]),
    }
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End: