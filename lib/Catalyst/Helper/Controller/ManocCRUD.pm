package Catalyst::Helper::Controller::ManocCRUD;

use Class::Load;
use namespace::autoclean;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin:../lib";

use File::Spec::Functions qw(catdir catfile canonpath);
use HTML::FormHandler::Generator::DBIC;

=head1 NAME

Catalyst::Helper::Controller::Manoc::CRUD

=head1 SYNOPSIS

    $ script/manoc_create.pl controller Manoc::CRUD ResultClass


=head1 DESCRIPTION 

This creates (1) a CRUD controller (2) a form for create/update
 operations (3) templates for the specified DB Class

=head1 METHODS

=head2 mk_compclass

    Where all the stuff is done.

=over

=back

=head1 AUTHOR

The Manoc Team

=head1 SEE ALSO

L<Catalyst::Controller>
L<Manoc::Form::Base>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub mk_compclass {
  my $self = shift;
  my $helper = shift;
  my @args = @_;
  
  my $schema_class = "Manoc::DB";
  my $model_class = "Manoc::Model::ManocDB";

  my $model_name = $helper->{name};
  my $controller_class = "$helper->{app}::Controller::$model_name";

  my $manoc_base_path = canonpath(catdir( $FindBin::Bin, ".."));
  my $manoc_lib_path  = catdir("lib", split( /::/, $helper->{app} ) );

  Class::Load::load_class($schema_class);
  my $schema = $schema_class->connect;
  my $source = $schema->source( $model_name );
  
  print "controller_class = $controller_class\n";
  print "app path $manoc_base_path\n";

  # prepare params for controller and templates
  my $params = {
      model => $model_name,
  };
  foreach my $col ($source->columns() ) {
      print "Scanning column $col\n";
      my $info = $source->column_info($col);
      my $default = $info->{default_value};
      my $nullable = $info->{is_nullable};
      my $autoinc = $info->{is_auto_increment};
      
      my $allowed = !$autoinc && !($default && $default =~ /(nextval|sequence|timestamp)/);
      my $required = (!$default || !$nullable) && !$autoinc;
      
      $allowed and push @{$params->{create_allows}}, $col;
      $required and push @{$params->{create_requires}}, $col;
      !$autoinc and push @{$params->{update_allows}}, $col;
      
      push @{$params->{columns}}, $col;
  }

  
  my $form_generator = HTML::FormHandler::Generator::DBIC->new(
      schema => $schema,
      rs_name => $model_name,
      class_prefix => 'Manoc::Form',
      schema_name  => $schema_class,
      label => 1,
  );
  my $form_content = $form_generator->generate_form;
  my $form_dir = catdir( $manoc_lib_path, "Form" );
  $helper->mk_dir($form_dir);
  my $form_file = catfile($form_dir, $model_name . ".pm" );
  $helper->mk_file($form_file, $form_content);
  
  my $controller_file = catfile( $manoc_lib_path, "Controller",
                                             $model_name . ".pm" );
  $helper->render_file('compclass', $controller_file, $params);

  my $tmpl_dir = catdir( $manoc_base_path, "root", "src", lc($model_name));
  $helper->mk_dir($tmpl_dir);
  $helper->render_file('list_tt', catfile($tmpl_dir, 'list.tt'), $params);
  $helper->render_file('form_tt', catfile($tmpl_dir, 'form.tt'), $params);
  $helper->render_file('view_tt', catfile($tmpl_dir, 'view.tt'), $params);
}

1;
__DATA__
=begin pod_to_ignore
__form_tt__
[% TAGS <+ +> %]
[%  META
    title='Create/Edit <+ model +> '
    section='Section'
    subsection='Subsection'
%]

<div class="buttons">
[% form.render %]
    </div>
__list_tt__
[% TAGS <+ +> %]
[% META
   tile='List <+ model +>'
   section='Section'
   subsection='Subsection'
   use_table=1
-%]
<div class="buttons create_btn">
<a href="[% c.uri_for_action('/<+ $model.lower +>/create') %]" >
   [% ui_icon('circle-plus') %] Create</a>
 [% add_css_create_btn %]
</div>
[% init_table('list') %]
 <table class="display" id="list">
   <thead>
     <tr>
<+ FOREACH col IN columns +>
        <th><+ col +></th>
<+ END +>
        <th></th>
     </tr>
   </thead>
   <tbody>
[% FOREACH o IN objects %]
         <tr>
<+ FOREACH col IN columns +>
 	 <td>[% o.<+ attr+> | html %]</td>
<+ END +>
 	 <td><a href=[% c.uri_for_action('/<+ model.lower +>/view', [o.id]) %]>View</a></td>
         </tr>
[% END %]
   </tbody>
</table>
__view_tt__
[% TAGS <+ +> %]
[% META
   title='View <+ model +>'
   section='Section'
   subsection='Subsection'
   use_table=1
-%]
    <table id="info">
      <+ FOREACH col IN columns +>
        <tr>
        <th><+ col +></th>
        <td>[% o.<+ attr+> | html %]</td>
        </tr>
      <+ END +>
    </table>
    [% add_css_tableinfo -%]
    <p>
      <div class="buttons">	
	<a href=[%c.uri_for_action('<+ model.lower +>/edit', [object.id]) %]> [% ui_icon('pencil') %] Edit</a>
	&nbsp;<a href=[% c.uri_for_action('<+ model.lower +>/delete', [object.id]) %]>
	[% ui_icon('closethick') %] Delete</a>
      </div>
    </p>
__controller__
# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::[% model %];
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }

use Manoc::Form::[% model %];

=head1 NAME

Manoc::Controller::[% model %] - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

has 'object_form' => (
    isa => 'Manoc::Form::[% model %]',
    is => 'rw',
    lazy => 1,
    default => sub { Manoc::Form::[% model %]->new }
);

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path() : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for_action( '[% model.lower %]/list' ) );
    $c->detach();
}



=head2 base

=cut

sub base : Chained('/') : PathPart('[% model.lower %]') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::[% model %]') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) { my (
    $self, $c, $id ) = @_;

    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !$c->stash->{object} ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=Head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $obj = $c->stash->{'object'};

    $c->stash( template => '[% model.lower %]/view.tt' );
}

sub list : Chained('base') PathPart('list') Args(0)
{
   my ( $self, $c ) = @_;

   my @objectes = $c->stash->{resultset}->all;
   $c->stash(
       objects => \@objects,
       template => '[% model.lower %]/list.tt'
   );
}

=head2 create

=cut

sub create : Chained('base') PathPart('create') Args(0)
{
    my ( $self, $c ) = @_;

    my $attrs = {}
    $c->stash( object  => $c->stash->{resultset}->new_result($attrs) );
    return $self->form($c);
}

=head2 edit

=cut

sub edit : Chained('object') PathPart('edit') Args(0)
{
    my ( $self, $c ) = @_;
    return $self->form($c);
}

=head2 form

Used by add and edit

=cut

sub form
{
    my ( $self, $c ) = @_;

    $c->stash(
	form => $self->object_form,
	template => '[% model.lower %]/form.tt',
	action => $c->uri_for($c->action, $c->req->captures)
    );

    return unless $self->object_form->process( item => $c->stash->{object},
					      params => $c->req->parameters );
    $c->res->redirect( $c->uri_for($self->action_for('list')) );
}

sub delete : Chained('object') PathPart('delete') Args(0)
{
    my ( $self, $c ) = @_;

    $c->stash( default_backref => $c->uri_for('/[% model.lower %]/list') );

    if ( lc $c->req->method eq 'post' ) {
	$c->stash->{object}->delete;
	$c->flash( message => 'Object deleted.' );
        $c->detach('/follow_backref');
    } else {
        $c->stash( template => 'generic_delete.tt' );
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
