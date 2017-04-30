package App::Manoc::Form::HWAsset::Location;
#ABSTRACT: Role for defining a location block
use HTML::FormHandler::Moose::Role;

##VERSION

with 'App::Manoc::Form::TraitFor::RackOptions';

use App::Manoc::DB::Result::HWAsset;

has_field 'location' => (
    type     => 'Select',
    required => 1,
    label    => 'Location',
    widget   => 'RadioGroup',
    options  => [
        {
            value => App::Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE,
            label => 'Warehouse'
        },
        {
            value => App::Manoc::DB::Result::HWAsset->LOCATION_RACK,
            label => 'Rack'
        },
        {
            value => App::Manoc::DB::Result::HWAsset->LOCATION_ROOM,
            label => 'Specify'
        },
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
    empty_select => '--- Choose ---',
    required     => 0,

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-6">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'rack_level' => (
    label      => 'Level',
    type       => 'Text',
    required   => 0,
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_block 'location_block' => (
    render_list => [ 'building', 'room', 'floor' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'warehouse' => (
    type         => 'Select',
    empty_select => '--- Choose ---',
    required     => 0,
    label        => 'Warehouse',
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '--- Choose ---',
    required     => 0,
    label        => 'Building',
    do_wrapper   => 0,
    tags         => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
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
    label_class => ['col-sm-1'],
);

has_field 'room' => (
    type       => 'Text',
    label      => 'Room',
    size       => 16,
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-1'],
);

sub default_location {
    my $self = shift;
    my $item = $self->item;

    return unless $item;

    $item->is_in_warehouse and return DB::HWAsset->LOCATION_WAREHOUSE;
    $item->is_in_rack      and return DB::HWAsset->LOCATION_RACK;
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

sub options_warehouse {
    my $self = shift;
    return unless $self->schema;
    my @warehouses =
        $self->schema->resultset('Warehouse')->search( {}, { order_by => 'name' } )->all();

    my @selections;
    foreach my $b (@warehouses) {
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

before 'validate_form' => sub {
    my $self     = shift;
    my $params   = $self->params;
    my $location = $params->{location};

    my @required;
    if ( $location eq DB::HWAsset->LOCATION_ROOM ) {
        push @required, 'building';
    }
    if ( $location eq DB::HWAsset->LOCATION_RACK ) {
        push @required, 'rack';
    }

    foreach (@required) {
        my $field = $self->field($_);
        next unless $field && !$field->required;
        $self->add_required($field);    # save for clearing later.
        $field->required(1);
    }
};

sub update_model_location {
    my $self     = shift;
    my $values   = $self->value;
    my $item     = $self->item;
    my $location = $values->{location};

    if ( $location eq DB::HWAsset->LOCATION_WAREHOUSE ) {
        $item->move_to_warehouse( $values->{warehouse} );
    }
    elsif ( $location eq DB::HWAsset->LOCATION_ROOM ) {
        $item->move_to_room( $values->{building}, $values->{floor}, $values->{room} );
    }
    elsif ( $location eq DB::HWAsset->LOCATION_RACK ) {
        $item->move_to_rack( $values->{rack} );
    }
    else {
        # unknown value, do nothing
        return;
    }

    delete $values->{warehouse};
    delete $values->{location};
    delete $values->{building};
    delete $values->{floor};
    delete $values->{room};
    delete $values->{rack};
    delete $values->{rack_level};

    $self->_set_value($values);
}

no HTML::FormHandler::Moose::Role;
1;
