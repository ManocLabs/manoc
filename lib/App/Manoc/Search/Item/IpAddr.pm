# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Item::IpAddr;

use Moose;

extends 'App::Manoc::Search::Item::Group';

has '+item_type' => ( default => 'ipaddr' );

has addr => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_addr { $_[0]->match }

sub _build_key {
    my $ip = $_[0]->addr;
    join( "", ( map { sprintf( "%03d", $_ ) } split( /\./, $ip ) ) );
}

no Moose;
__PACKAGE__->meta->make_immutable;
