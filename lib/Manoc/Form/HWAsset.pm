package Manoc::Form::HWAsset;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Horizontal';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::RackOptions';

use Manoc::DB::Result::HWAsset;

use namespace::autoclean;

has '+item_class' => ( default => 'HWAsset' );
has '+name'       => ( default => 'form-hwasset' );
has '+html_prefix' => ( default => 1 );

use constant {
    LOCATION_WAREHOUSE => 'w',
    LOCATION_RACK      => 'r',
    LOCATION_SPECIFY   => 's',
};

has hide_location => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

sub build_render_list {
    my $self = shift;

    my @list;

    push @list,
        'type',
        'inventory',
        'vendor', 'model', 'serial';

    unless ($self->hide_location) {
        push @list,
            'location',
            'location_block',
            'rack_block';
    }

    push @list,
        'save',
        'csrf_token';

    return \@list;
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
    label    => 'Inventory',
);

has_field 'vendor' => (
    type     => 'Text',
    size     => 32,
    required => 1,
    label    => 'Vendor',
);

has_field 'model' => (
    type     => 'Text',
    size     => 32,
    required => 1,
    label    => 'Model',
);

has_field 'serial' => (
    type  => 'Text',
    size  => 32,
    label => 'Serial',
);

has_field 'location' => (
    type     => 'Select',
    required => 1,
    label    => 'Location',
    widget   => 'RadioGroup',
    options  => [
        { value => LOCATION_WAREHOUSE, label => 'Warehouse' },
        { value => LOCATION_RACK,      label => 'Rack' },
        { value => LOCATION_SPECIFY,   label => 'Specify' },
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
    required     => 0,

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


has_block 'location_block' => (
    render_list => [ 'building', 'room', 'floor' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '---Choose a Building---',
    required     => 0,
    label        => 'Building',
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
);


has_field 'floor' => (
    type  => 'Text',
    label => 'Floor',
    size  => 4,

    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-1'],
);

has_field 'room' => (
    type  => 'Text',
    label => 'Room',
    size  => 16,
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-1'],
);

sub default_location {
    my $self = shift;
    my $item = $self->item;

    return unless $item;

    $item->in_warehouse and return LOCATION_WAREHOUSE;
    $item->rack and return LOCATION_RACK;
    return LOCATION_SPECIFY;
}

sub options_building {
    my $self = shift;
    return unless $self->schema;
    my @buildings =
        $self->schema->resultset('Building')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@buildings) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

sub options_rack {
    my $self = shift;
    return unless $self->schema;
    return $self->get_rack_options;
}

sub options_type {
    my @results;
    while ( my ( $key, $attrs ) = each(%Manoc::DB::Result::HWAsset::TYPE) ) {
        push @results, { value => $key, label => $attrs->{label} };
    }
    return @results;
}

has 'preset_type' => ( is => 'rw', isa => 'Str' );

before 'process' => sub {
    my $self = shift;

    my %args = @_;

    if (my $type = $args{preset_type}) {
        push @{ $self->inactive }, 'type';
        $self->defaults->{type} = $type;
    }

    if ($args{hide_location}) {
        push @{ $self->inactive }, qw(location building rack room floor);
        $self->defaults->{location} = LOCATION_WAREHOUSE;
    }
};

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    $values->{location} eq LOCATION_WAREHOUSE and
        $values->{in_warehouse} = 1;

    if ( $self->preset_type ) {
        $values->{type} = $self->preset_type;
    }
    $self->_set_value($values);

    super();
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
