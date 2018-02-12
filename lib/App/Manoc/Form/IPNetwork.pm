package App::Manoc::Form::IPNetwork;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::IPAddr';

use HTML::FormHandler::Types ('IPAddress');
use App::Manoc::IPAddress::IPv4Network;
use App::Manoc::IPAddress::IPv4;

has '+name' => ( default => 'form-ipnetwork' );

has '+item_class' => ( default => 'IPNetwork' );

sub build_render_list {
    [
        'network_block', 'name',  'vlan_id', 'default_gw',
        'description',   'notes', 'save',    'csrf_token'
    ];
}

has_block 'network_block' => (
    render_list => [ 'address', 'prefix' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'address' => (
    apply          => [IPAddress],
    size           => 15,
    required       => 1,
    label          => 'Address',
    do_wrapper     => 0,
    inflate_method => \&inflate_ipv4,

    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-6">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
    element_attr => { placeholder => 'IP Address' }
);

has_field 'prefix' => (
    type       => 'Integer',
    required   => 1,
    size       => 2,
    label      => 'Prefix',
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
    element_attr => { placeholder => '24' }
);

has_field 'name' => (
    type         => 'Text',
    required     => 1,
    label        => 'Name',
    element_attr => { placeholder => 'Network name' }
);

has_field 'vlan_id' => (
    type         => 'Select',
    label        => 'Vlan',
    empty_select => '---Choose a VLAN---',
);

has_field 'default_gw' => (
    apply        => [IPAddress],
    size         => 15,
    required     => 0,
    label        => 'Default GW',
    element_attr => { placeholder => 'Default gateway (optional)' }

);

has_field 'description' => (
    type  => 'TextArea',
    label => 'Description',
);

has_field 'notes' => ( type => 'TextArea' );

sub options_vlan_id {
    my $self = shift;

    return unless $self->schema;
    my $rs = $self->schema->resultset('Vlan')->search( {}, { order_by => 'id' } );
    return map +{ value => $_->id, label => $_->name . " (" . $_->id . ")" }, $rs->all();
}

override validate_model => sub {
    my $self   = shift;
    my $item   = $self->item;
    my $values = $self->values;

    super();

    if ( $item->in_storage ) {

        my $saved_prefix  = $item->prefix;
        my $saved_address = $item->address;

        $item->address( $values->{address} );
        $item->prefix( $values->{prefix} );

        if ( $item->is_outside_parent ) {
            $self->add_form_error('Network would be outside its parent');
        }
        else {
            $item->is_inside_children and
                $self->add_form_error('Network would be inside a child');
        }

        $item->prefix($saved_prefix);
        $item->address($saved_address);
    }

    if ( $values->{default_gw} && $values->{address} && $values->{prefix} ) {
        my $net =
            App::Manoc::IPAddress::IPv4Network->new( $values->{address}, $values->{prefix} );
        my $gw = App::Manoc::IPAddress::IPv4->new( $values->{default_gw} );
        $net->contains_address($gw) or
            $self->field('default_gw')->add_error('Gateway outside network');
    }

};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
