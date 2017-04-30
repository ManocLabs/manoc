# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Form::Uplink;

use strict;
use warnings;

use HTML::FormHandler::Moose;

extends 'HTML::FormHandler';
has '+widget_wrapper' => ( default => 'None' );

has 'schema' => ( is => 'rw' );

has 'device' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
    trigger  => sub { shift->set_device(@_) }
);

sub set_device {
    my ( $self, $device ) = @_;
    $self->schema( $device->result_source->schema );
}

has_field 'interfaces'             => ( type => 'Repeatable' );
has_field 'interfaces.label'       => ( type => 'Hidden' );
has_field 'interfaces.name'        => ( type => 'PrimaryKey' );
has_field 'interfaces.uplink_flag' => ( type => 'Boolean', label => 'Uplink' );

sub init_object {
    my $self   = shift;
    my $device = $self->device;

    my %uplinks = map { $_->interface => 1 } $device->uplinks->all;
    my @iface_list;

    my $rs = $device->ifstatus;
    while ( my $r = $rs->next() ) {
        my ( $controller, $port ) = split /[.\/]/, $r->interface;
        my $lc_if = lc( $r->interface );
        my $label = $r->interface;
        $r->description and $label .= ' (' . $r->description . ')';

        push @iface_list, {
            controller  => $controller,                 # for sorting
            port        => $port,                       # for sorting
            name        => $r->interface,
            label       => $label,
            uplink_flag => $uplinks{ $r->interface },
        };
    }
    @iface_list =
        sort { ( $a->{controller} cmp $b->{controller} ) || ( $a->{port} <=> $b->{port} ) }
        @iface_list;

    return { interfaces => \@iface_list };
}

sub update_model {
    my $self = shift;

    my $device     = $self->device;
    my $interfaces = $self->value->{interfaces};
    $self->schema->txn_do(
        sub {
            $device->uplinks()->delete();
            foreach my $i (@$interfaces) {
                $i->{uplink_flag} and
                    $device->add_to_uplinks( { interface => $i->{name} } );
            }
        }
    );
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
