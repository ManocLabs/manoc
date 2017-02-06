# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::DiscoverSession;

use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Horizontal';
with 'Manoc::Form::TraitFor::SaveButton';

use namespace::autoclean;
use HTML::FormHandler::Types ('IPAddress');

has '+name'        => ( default => 'form-discoversession' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'DiscoverSession' );

sub build_render_list {
    [ 'range_block', 'snmp_block', 'use_netbios', 'save', 'csrf_token', ];
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

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
    element_attr => { placeholder => 'IP Address' }
);

has_block 'snmp_block' => (
    render_list => [ 'use_snmp', 'snmp_community' ],
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

has_field 'snmp_community' => (
    type  => 'Text',
    size  => 15,
    label => 'Community',

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
    element_attr => { placeholder => 'public' },
);

has_field 'use_netbios' => (
    type     => 'Select',
    required => 1,
    label    => 'Netbios',
    widget   => 'RadioGroup',
    options  => [ { value => 1, label => 'Yes' }, { value => 0, label => 'No' } ],
);

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    $values->{status}    = Manoc::DB::Result::DiscoverSession->STATUS_NEW;
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
