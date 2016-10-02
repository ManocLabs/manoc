package Manoc::Form::HWAsset;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Horizontal';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::RackOptions';

use aliased 'Manoc::DB::Result::HWAsset' => 'DB::HWAsset';

use namespace::autoclean;

has '+item_class' => ( default => 'HWAsset' );
has '+name'       => ( default => 'form-hwasset' );
has '+html_prefix' => ( default => 1 );

has hide_location => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

has 'preset_type' => (
    is   => 'rw',
    isa  => 'Str'
);

sub build_render_list {
    my $self = shift;

    my @list;

    push @list,
        'inventory',
        'vendor', 'model', 'serial',
        'location',
        'location_block',
        'rack_block',
        'save',
        'csrf_token';

    return \@list;
}

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
    noupdate => 1,
    options  => [
        { value => DB::HWAsset->LOCATION_WAREHOUSE, label => 'Warehouse' },
        { value => DB::HWAsset->LOCATION_RACK,      label => 'Rack' },
        { value => DB::HWAsset->LOCATION_ROOM,   label => 'Specify' },
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

    $item->is_in_warehouse and return DB::HWAsset->LOCATION_WAREHOUSE;
    $item->is_in_rack and return DB::HWAsset->LOCATION_RACK;
    return DB::HWAsset->LOCATION_ROOM;
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

before 'process' => sub {
    my $self = shift;

    my %args = @_;

    if ( $args{preset_type}) {
        push @{ $self->inactive }, 'type';
    }

    if ($args{hide_location}) {
        push @{ $self->inactive },
            qw(location building rack rack_level room floor
               location_block rack_block);
        $self->defaults->{location} = DB::HWAsset->LOCATION_WAREHOUSE;
    }
};

override validate_model => sub {
    my $self = shift;
    my $item = $self->item;
    my $found_error;

    # location field are not validating when not entered :D
    if ( ! $self->hide_location ) {

        # when moving to warehouse check for in_use
        my $location_field = $self->field('location');
        if ($location_field->value eq DB::HWAsset->LOCATION_WAREHOUSE &&
                $item->in_use)
            {
                $location_field->( "Asset is in use, cannot be moved to warehouse" );
                $found_error++;
            }
    }

    $found_error += super();

    return $found_error;
};

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->value;
    my $item   = $self->item;

    $values->{type} = $self->preset_type;

    $self->hide_location and
        $values->{location} = DB::HWAsset->LOCATION_WAREHOUSE;

    my $location = $values->{location};
    if ($location eq DB::HWAsset->LOCATION_WAREHOUSE) {
        $item->move_to_warehouse();
    }
    if ($location eq DB::HWAsset->LOCATION_ROOM) {
        $item->move_to_room(
            $values->{building},
            $values->{floor},
            $values->{room});
    }
    if ($location eq DB::HWAsset->LOCATION_RACK) {
        $item->move_to_rack($values->{rack});
    }

    delete $values->{building};
    delete $values->{rack};
    delete $values->{room};
    delete $values->{floor};

    $self->_set_value($values);

    super();
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
