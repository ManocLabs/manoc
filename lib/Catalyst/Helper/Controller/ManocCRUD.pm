package Catalyst::Helper::Controller::ManocCRUD;

use strict;
use warnings;

##VERSION

use Class::Load;
use namespace::autoclean;

use File::Spec::Functions qw(catdir catfile canonpath);
use Catalyst::Helper::Controller::ManocCRUD::Form;

=head1 NAME

Catalyst::Helper::Controller::ManocCRUD

=head1 SYNOPSIS

$ script/manoc_create.pl controller <modelname> ManocCRUD

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
L<App::Manoc::Form::Base>
L<MAnoc::ControllerRole::CommonCRUD>

=head1 CAVEATS

Form class must be customized in order to use App::Manoc::Form::Base.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub mk_compclass {
    my $self   = shift;
    my $helper = shift;
    my @args   = @_;

    my $schema_class = "App::Manoc::DB";
    my $model_class  = "App::Manoc::Model::ManocDB";

    my $model_name       = $helper->{name};
    my $controller_class = "$helper->{app}::Controller::$model_name";

    my $manoc_base_path = canonpath( catdir( $FindBin::Bin, ".." ) );
    my $manoc_lib_path  = catdir( "lib", split( /::/, $helper->{app} ) );

    Class::Load::load_class($schema_class);
    my $schema = $schema_class->connect;
    my $source = $schema->source($model_name);

    print "controller_class = $controller_class\n";
    print "app path $manoc_base_path\n";

    # prepare params for controller and templates
    my $params = { model => $model_name, };
    foreach my $col ( $source->columns() ) {
        print "Scanning column $col\n";
        my $info     = $source->column_info($col);
        my $default  = $info->{default_value};
        my $nullable = $info->{is_nullable};
        my $autoinc  = $info->{is_auto_increment};

        my $allowed  = !$autoinc && !( $default && $default =~ /(nextval|sequence|timestamp)/ );
        my $required = ( !$default || !$nullable ) && !$autoinc;

        $allowed  and push @{ $params->{create_allows} },   $col;
        $required and push @{ $params->{create_requires} }, $col;
        !$autoinc and push @{ $params->{update_allows} },   $col;

        push @{ $params->{columns} }, $col;
    }

    my $form_generator = Catalyst::Helper::Controller::ManocCRUD::Form->new(
        schema       => $schema,
        rs_name      => $model_name,
        class_prefix => 'App::Manoc::Form',
        schema_name  => $schema_class,
        label        => 1,
    );
    my $form_content = $form_generator->generate_form;
    my $form_dir     = catdir( $manoc_lib_path, "Form" );
    $helper->mk_dir($form_dir);
    my $form_file = catfile( $form_dir, $model_name . ".pm" );
    $helper->mk_file( $form_file, $form_content );

    my $controller_file = catfile( $manoc_lib_path, "Controller", $model_name . ".pm" );
    $helper->render_file( 'controller', $controller_file, $params );

    my $tmpl_dir = catdir( $manoc_base_path, "root", "src", "pages", lc($model_name) );
    $helper->mk_dir($tmpl_dir);
    $helper->render_file( 'list_tt',   catfile( $tmpl_dir, 'list.tt' ),   $params );
    $helper->render_file( 'create_tt', catfile( $tmpl_dir, 'create.tt' ), $params );
    $helper->render_file( 'form_tt',   catfile( $tmpl_dir, 'form.tt' ),   $params );
    $helper->render_file( 'view_tt',   catfile( $tmpl_dir, 'view.tt' ),   $params );
}

1;
__DATA__
=begin pod_to_ignore
__form_tt__
[% TAGS <+ +> -%]
[% form.render %]
__list_tt__
[% TAGS <+ +> -%]
[% META
   use_table=1
-%]
[%
 page.title='List <+ model +>'
 -%]
<div id="tabletoolbar">
[%- IF c.check_permission('<+ model.lower +>.create') -%]
 <a href="[% c.uri_for_action('<+ model.lower +>/create') %]" class="btn btn-sm btn-primary">[% bootstrap_icon("plus") %] Add</a>
[% END -%]
</div>

[% init_table('<+ model.lower +>_list', { toolbar="tabletoolbar" }) %]

<table class="table" id="<+ model.lower +>_list">
   <thead>
     <tr>
<+- FOREACH col IN columns +>
        <th><+ col +></th>
<+- END +>
        <th></th>
     </tr>
   </thead>
   <tbody>
[% FOREACH object IN object_list %]
         <tr>
<+- FOREACH col IN columns +>
 	 <td>[% object.<+ col +> | html %]</td>
<+- END +>
     	 <td><a href=[% c.uri_for_action('<+ model.lower +>/view', [object.id]) %]>View</a></td>
         </tr>
[% END %]
   </tbody>
</table>
__view_tt__
[% TAGS <+ +> -%]
[%
   page.title='View <+ model +>'
-%]
[% page.toolbar = BLOCK -%]
[%- IF c.check_permission(object, 'edit') || c.check_permission(object, 'delete') -%]
    <div class="btn-group">
    <a class="btn btn-primary [% 'disabled' UNLESS c.check_permission(object, 'edit') %]" href="[% c.uri_for_action('<+ model.lower +>/edit',[object.id]) %]">[% bootstrap_icon('pencil') %] Edit</a>
    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
      <span class="caret"></span>
    </button>
    <ul class="dropdown-menu dropdown-menu-right">
    <li class="[% 'disabled' UNLESS c.check_permission(object, 'delete') %]">
       <a href="[%c.uri_for_action('<+ model.lower +>/delete',[object.id]) %]">
       [% bootstrap_icon('trash') %] Delete</a></li>
    </ul>
  </div><!-- end btn group -->
[% END -%]

<div class="panel panel-default">
  <div class="panel-body">
    <dl class="dl-horizontal">
    <+- FOREACH col IN columns +>
      <dt><+ col +></dt>
      <dd>[% object.<+ col +> | html %]</dd>
     <+- END +>
    </dl>
  </div><!-- panel body -->
</div><!-- panel -->
__controller__
# Copyright 2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package App::Manoc::Controller::[% model %];
##VERSION
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'App::Manoc::ControllerRole::CommonCRUD';

use App::Manoc::Form::[% model %];

=head1 NAME

App::Manoc::Controller::[% model %] - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => '[% model.lower %]',
        }
    },
    class      => 'ManocDB::[% model %]',
    form_class => 'App::Manoc::Form::[% model %]',
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
