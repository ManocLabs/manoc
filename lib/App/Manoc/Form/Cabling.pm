package App::Manoc::Form::Cabling;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';

has '+name' => ( default => 'form-devcabling' );

has 'schema' => ( is => 'rw' );

has_field 'interface1' => (
    type         => 'Select',
    empty_select => '--- Select ---',
    required     => 1,
    do_wrapper   => 0,
);

has_field 'interface2' => (
    type         => 'Select',
    empty_select => '--- Select ---',
    required     => 0,
    do_wrapper   => 0,

);

has_field 'serverhw_nic' => (
    type         => 'Select',
    empty_select => '--- Select ---',
    required     => 0,
    do_wrapper   => 0,
);

has_field 'save' => (
    type  => 'Submit',
    value => "Save"
);

override validate_model => sub {
    my $self = shift;

    # some handy shortcuts
    my %active_fields = map { $_->name => 1 } $self->sorted_fields;

    my $interface1 = $active_fields{interface1} ? $self->field('interface1')->value : undef;
    my $serverhw_nic =
        $active_fields{serverhw_nic} ? $self->field('serverhw_nic')->value : undef;
    my $interface2 = $active_fields{interface2} ? $self->field('interface2')->value : undef;

    my $item = $self->item;

    if ( !defined($interface2) && !defined($serverhw_nic) ) {
        $self->add_form_error('Missing destination');
    }

    # check for overlapping cablings
    #TODO
};

override update_model => sub {
    my $self   = shift;
    my $values = $self->values;

    $self->schema->txn_do(
        sub {
            super();

            if ( $self->values->{interface2} ) {
                my $item   = $self->item;
                my $source = $self->source;
                my $rs     = $self->schema->resultset( $source->source_name );

                my $item2 = $rs->create(
                    {
                        interface1 => $item->interface2,
                        interface2 => $item->interface1,
                    }
                );
            }
        }
    );
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
