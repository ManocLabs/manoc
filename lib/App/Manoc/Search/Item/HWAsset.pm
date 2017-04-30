# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Item::HWAsset;
use Moose;

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'hwasset' );

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'vendor' => (
    is  => 'ro',
    isa => 'Str',
);

has 'model' => (
    is  => 'ro',
    isa => 'Str',
);

has 'inventory' => (
    is  => 'ro',
    isa => 'Str',
);

has 'serial' => (
    is  => 'ro',
    isa => 'Str',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args    = $_[0];
        my $hwasset = $args->{hwasset};
        if ($hwasset) {
            $args->{id} = $hwasset->id;
            $args->{bame} = $hwasset->label || '';

            $args->{vendor}    = $hwasset->vendor    || '';
            $args->{model}     = $hwasset->model     || '';
            $args->{serial}    = $hwasset->serial    || '';
            $args->{inventory} = $hwasset->inventory || '';
        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
