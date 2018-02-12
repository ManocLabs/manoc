package App::Manoc::Form::HWAsset;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::HWAsset::Location';

use aliased 'App::Manoc::DB::Result::HWAsset' => 'DB::HWAsset';

has '+item_class' => ( default => 'HWAsset' );
has '+name'       => ( default => 'form-hwasset' );

has hide_location => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

has 'type' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

sub build_render_list {
    my $self = shift;

    my @list;

    push @list,
        'inventory',
        'vendor', 'model', 'serial',
        'location',
        'warehouse',
        'location_block',
        'rack_block',
        'save',
        'csrf_token';

    return \@list;
}

has_field 'inventory' => (
    type  => 'Text',
    size  => 32,
    label => 'Inventory',
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

    # avoid update_model called for field validation!
    validate_method => sub { },
);

has_field 'serial' => (
    type  => 'Text',
    size  => 32,
    label => 'Serial',
);

before 'process' => sub {
    my $self = shift;

    my %args = @_;

    if ( $args{hide_location} ) {
        push @{ $self->inactive }, qw(location warehouse building rack rack_level room floor
            location_block rack_block);
        $self->defaults->{location} = DB::HWAsset->LOCATION_WAREHOUSE;
    }
};

override validate_model => sub {
    my $self        = shift;
    my $item        = $self->item;
    my $found_error = 0;

    # location field are not validating when not entered :D
    if ( !$self->hide_location ) {

        # when moving to warehouse check for in_use
        my $location_field = $self->field('location');
        if ( $item->in_storage &&
            $location_field->value eq DB::HWAsset->LOCATION_WAREHOUSE &&
            $item->in_use )
        {
            $location_field->("Asset is in use, cannot be moved to warehouse");
            $found_error++;
        }
    }

    return super() || $found_error;
};

before 'update_model' => sub {
    my $self   = shift;
    my $values = $self->value;
    my $item   = $self->item;

    $item->type( $self->type );

    $self->hide_location and
        $values->{location} = DB::HWAsset->LOCATION_WAREHOUSE;
    $self->_set_value($values);
    $self->update_model_location();
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
