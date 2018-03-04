package App::Manoc::Form::DiscoverSession;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with
    'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::IPAddr';
use HTML::FormHandler::Types ('IPAddress');

has '+name'        => ( default => 'form-discoversession' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'DiscoverSession' );

sub build_render_list {
    [ 'range_block', 'use_block', 'credentials', 'save', 'csrf_token', ];
}

has_block 'range_block' => (
    render_list => [ 'from_addr', 'to_addr' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'from_addr' => (
    apply    => [IPAddress],
    size     => 15,
    required => 1,
    label    => 'From',

    inflate_method => \&inflate_ipv4,

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],

    element_attr => { placeholder => 'IP Address' }
);

has_field 'to_addr' => (
    size     => 15,
    required => 1,
    label    => 'To',

    inflate_method => \&inflate_ipv4,

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
    element_attr => { placeholder => 'IP Address' }
);

has_block 'use_block' => (
    render_list => [ 'use_snmp', 'use_netbios' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'use_snmp' => (
    type     => 'Select',
    required => 1,
    label    => 'SNMP',
    widget   => 'RadioGroup',
    options  => [ { value => 1, label => 'Yes' }, { value => 0, label => 'No' } ],

    do_wrapper => 0,

    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        inline         => 1,
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'use_netbios' => (
    type     => 'Select',
    required => 1,
    label    => 'Netbios',
    widget   => 'RadioGroup',
    options  => [ { value => 1, label => 'Yes' }, { value => 0, label => 'No' } ],

    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        inline         => 1,
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'credentials' => (
    type  => 'Select',
    label => 'Credentials',
);

sub options_credentials {
    my $self = shift;
    return unless $self->schema;
    my @credentials =
        $self->schema->resultset('Credentials')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@credentials) {
        my $option = {
            label => $b->name,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    $values->{status}    = App::Manoc::DB::Result::DiscoverSession->STATUS_NEW;
    $values->{next_addr} = $values->{from_addr};
    $self->_set_value($values);

    super();
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
