# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Device::Create;

use strict;
use warnings;

use HTML::FormHandler::Moose;
use Manoc::DB::Result::HWAsset;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::RackOptions';
with 'Manoc::Form::TraitFor::Horizontal';

use HTML::FormHandler::Types ('IPAddress');

has '+name'        => ( default => 'form-device' );
has '+html_prefix' => ( default => 1 );

sub build_render_list {
    [
        'name',
        'mng_block',
        'hwasset_block',
        'rack_block',
        'notes',
        'save',
        'csrf_token'
    ];
}

has_field 'name' => (
    type     => 'Text',
    required => 0,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid name'
        },
    ]
);

has_block 'hwasset_block' => (
    render_list => [ 'hwasset', 'asset_button' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'hwasset' => (
    type         => 'Select',
    label        => 'Hardware asset',
    empty_select => '--- Select asset ---',
    required     => 1,

    do_wrapper => 0,
    tags => {
        before_element => '<div class="col-sm-8">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);

has_field 'asset_button' => (
    type           => 'Button',
    widget         => 'ButtonTag',
    element_attr   => {
        class => [ 'btn', 'btn-primary' ],
        href => '#',
    },
    widget_wrapper => 'None',
    value          => "Add",
);

has_block 'mng_block' => (
    render_list => [ 'mng_address', 'mng_url_format' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'mng_address' => (
    apply      => [IPAddress],
    label    => 'Management Address',
    required => 1,
    element_attr => { placeholder => 'IP Address' },

    do_wrapper => 0,
    tags => {
        before_element => '<div class="col-sm-5">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);

has_field 'mng_url_format' => (
    type         => 'Select',
    label        => 'URL type',
    empty_select => '- None -',

    do_wrapper => 0,
    tags => {
        before_element => '<div class="col-sm-3">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);

has_block 'rack_block' => (
    render_list => [ 'rack', 'rack_level' ],
    tag         => 'div',
    class       => ['form-group'],
);

#Location
has_field 'rack' => (
    type         => 'Select',
    label        => 'Rack',
    empty_select => '--- Select a rack ---',
    required     => 1,

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-6">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);

has_field 'rack_level' => (
    label    => 'Level',
    type     => 'Text',
    required => 0,
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);

has_field 'notes' => ( type => 'TextArea' );

sub options_mng_url_format {
    my $self = shift;
    return unless $self->schema;

    my $rs = $self->schema->resultset('MngUrlFormat')->search( {}, { order_by => 'name' } );

    return map +{ value => $_->id, label => $_->name }, $rs->all();
}

sub options_hwasset {
    my $self = shift;
    return unless $self->schema;

    return map +{
        value => $_->id,
        label => $_->label,
    }, $self->schema->resultset('HWAsset')->unused_devices()->all();
}

sub options_rack {
    my $self = shift;

    return unless $self->schema;

    return $self->get_rack_options;
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
