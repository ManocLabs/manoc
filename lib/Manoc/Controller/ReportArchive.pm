# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::ReportArchive;
use Moose;
use namespace::autoclean;
use Manoc::Utils qw(print_timestamp);
use Data::Dumper;
BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::ReportArchive - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for('/reportarchive/list') );
}

=head2 base

=cut

sub base : Chained('/') : PathPart('reportarchive') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::ReportArchive') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) {

    # $id = primary key
    my ( $self, $c, $id ) = @_;

    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !$c->stash->{object} ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $obj        = $c->stash->{'object'};
    my $type       = $obj->type;
    my $report_obj = $obj->s_class;

    $c->stash(
        report_obj  => $report_obj,
        timestamp   => print_timestamp( $obj->timestamp ),
        report_name => $obj->name,
    );

    $c->stash( template => "report_archive/$type.tt" );
}

=head2 view

=cut

sub view_type : Chained('base') : PathPart('view_type') : Args(1) {
    my ( $self, $c, $category ) = @_;

    if ( !$category ) {
        $c->stash( error_msg => "Report's type not specified!" );
        $c->detach('/error/index');
    }

    my @rs = $c->stash->{resultset}->search( { type => $category } );
    my @reports = map +{
        id        => $_->id,
        type      => $_->type,
        name      => $_->name,
        timestamp => print_timestamp( $_->get_column('timestamp') ),
    }, @rs;

    $c->stash(
        reports  => \@reports,
        template => 'report_archive/view_type.tt'
    );

}

=head2 list

SuperMambroQuery:

SELECT self.id, self.type, self.timestamp, self.s_class, other.max_tm FROM report_archive self 
JOIN (SELECT type, max(timestamp) as max_tm FROM report_archive GROUP BY type) other 
on self.type = other.type and self.timestamp = other.max_tm

=cut

sub list : Chained('base') : PathPart('list') : Args() {
    my ( $self, $c ) = @_;

    my $sql_string =
        "(SELECT type, name,  max(timestamp) as max_tm FROM report_archive GROUP BY type, name )";
    my @r = $c->stash->{resultset}->search(
        {},
        {
            select => [ 'me.id', 'me.timestamp', 'me.type', 'me.name' ],
            from   => [
                { 'me' => 'report_archive' },
                [
                    { 'other' => \$sql_string },
                    {
                        'me.type'      => 'other.type',
                        'me.timestamp' => 'other.max_tm'
                    }
                ]
            ]
        }
    );

    my @reports = map +{
        id        => $_->id,
        type      => $_->type,
        name      => $_->name,
        timestamp => print_timestamp( $_->get_column('timestamp') ),
    }, @r;

    $c->stash( reports  => \@reports );
    $c->stash( template => 'report_archive/list.tt' );
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
