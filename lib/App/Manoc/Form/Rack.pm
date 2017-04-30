package App::Manoc::Form::Rack;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';

with
    'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-rack' );
has '+html_prefix' => ( default => 1 );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Name',
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '---Choose a Building---',
    required     => 1,
    label        => 'Building',
);

has_field 'floor' => (
    type     => 'Integer',
    required => 1,
    label    => 'Floor',
);

has_field 'room' => (
    type     => 'Text',
    size     => 32,
    required => 1
);

has_field 'notes' => (
    type     => 'TextArea',
    label    => 'Notes',
    required => 0,
    row      => 3,
);

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

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
