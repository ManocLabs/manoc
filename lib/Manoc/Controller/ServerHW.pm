# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::ServerHW;
use Moose;
use namespace::autoclean;

use Manoc::Form::ServerHW;
use Manoc::Form::CSVImport::ServerHW;

BEGIN { extends 'Catalyst::Controller'; }
with "Manoc::ControllerRole::CommonCRUD";
with "Manoc::ControllerRole::JSONView";


=head1 NAME

Manoc::Controller::ServerHW - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'serverhw',
        }
    },
    class                   => 'ManocDB::ServerHW',
    form_class              => 'Manoc::Form::ServerHW',
    enable_permission_check => 1,
    view_object_perm        => undef,

    json_columns            => [ 'id', 'inventory', 'model', 'serial' ],

);

=head1 ACTIONS



=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $copy_id = $c->req->query_parameters->{'copy'};
    if ($copy_id) {
        my $original = $c->stash->{resultset}->find($copy_id);
        if ($original) {
            $c->log->debug("copy server from $copy_id");
            my %cols = $original->get_columns;
            delete $cols{hwasset_id};
            foreach ( qw(model vendor) ) {
                $cols{$_} = $original->hwasset->get_column($_);
            }

            $c->stash( form_defaults => \%cols );
        }
    }
};



=head2 list_decommissioned

List decommissioned devices

=cut

sub list_decommissioned : Chained('base') : PathPart('decommissioned') {
    my ( $self, $c ) = @_;

    my $rs      = $c->stash->{resultset};
    $c->stash( decommissioned_device_list => $self->get_object_list($c, {decommissioned => 1}) );
}

=head2 import_csv

Import a server hardware list from a CSV file

=cut


sub import_csv : Chained('base') : PathPart('importcsv') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( 'serverhw', 'create' );
    my $rs = $c->stash->{resultset};

    my $upload;
    $c->req->method eq 'POST' and $upload = $c->req->upload('file');


    my $form = Manoc::Form::CVSImport::ServerHW->new(
        ctx              => $c,
        resultset        => $rs,
    );
    $c->stash->{form} = $form;

    my %process_params;
    $process_params{params} = $c->req->parameters;
    $upload and $process_params{params}->{file} = $upload;
    my $process_status = $form->process(%process_params);

    return unless $process_status;
}


=head2 get_object_list

=cut

sub get_object_list {
    my ( $self, $c, $opts ) = @_;

    my $decommissioned = $opts->{decommissioned} ? 1 : 0;

    return [
        $c->stash->{resultset}->search(
            {
                decommissioned => $decommissioned
            },
            {
                prefetch =>
                    { 'hwasset' => { 'rack' => 'building' } }
                },
        )
    ];
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
