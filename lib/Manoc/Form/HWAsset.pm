package Manoc::Form::HWAsset;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Horizontal';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::RackOptions';

use namespace::autoclean;

has '+item_class' => ( default => 'HWAsset' );
has '+name'       => ( default => 'form-hwasset' );
has '+html_prefix' => ( default => 1 );

sub build_render_list {
    [
        'type',
        'inventory',
        'vendor', 'model', 'serial',
        'location',
        'building', 'location_block',
        'rack_block',
        'save',
        'csrf_token'
    ];
}

has_field 'type' => (
    type     => 'Select',
    size     => 1,
    required => 1,
    label    => 'Asset type',
);

has_field 'inventory' => (
    type     => 'Text',
    size     => 32,
    required => 1,
    label    => 'Inventory number',
);

has_field 'vendor' => (
    type     => 'Text',
    size     => 32,
    required => 1,
    label    => 'vendor',
);

has_field 'model' => (
    type     => 'Text',
    size     => 32,
    required => 1,
    label    => 'model',
);

has_field 'serial' => (
    type  => 'Text',
    size  => 32,
    label => 'Serial No',
);

has_field 'location' => (
    type     => 'Select',
    required => 1,
    label    => 'Location',
    widget   => 'RadioGroup',
    options  => [
        { value => 'w', label => 'Warehouse' },
        { value => 'r', label => 'Rack' },
        { value => 's', label => 'Specify' },
    ],
    wrapper_tags => { inline => 1 },
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

has_field 'building' => (
    type  => 'Select',
    label => 'building',
);

has_block 'location_block' => (
    render_list => [ 'room', 'floor' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'floor' => (
    type  => 'Text',
    label => 'Floor',
    size  => 4,
    label => 'floor',
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);

has_field 'room' => (
    type  => 'Text',
    label => 'Room',
    size  => 16,
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],

);


sub options_type {
    my @results;
    while ( my ( $key, $attrs ) = each(%Manoc::DB::Result::HWAsset::TYPE) ) {
        push @results, { value => $key, label => $attrs->{label} };
    }
    return @results;
}

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
