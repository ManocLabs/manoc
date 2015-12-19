# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::InflateColumn::IPv4;

use strict;
use warnings;
use Manoc::IPAddress::IPv4;

sub register_column {
    my $self = shift;
    my ( $column, $info, $args ) = @_;
    $self->next::method(@_);

    return unless $info->{'ipv4_address'};

    $self->inflate_column(
        $column => {
            inflate => \&inflate_ipv4_column,
            deflate => \&deflate_ipv4_column,
        }
    );
}

sub inflate_ipv4_column {
    my ( $value, $obj ) = @_;
    return Manoc::IPAddress::IPv4->new($value) if defined($value);
}

sub deflate_ipv4_column {
    my ( $value, $obj ) = @_;
    return $value->padded if defined($value);
}

=head1 NAME

DBIx::Class::InflateColumn::Serializer - Inflator for IP v4 addresses

=head1 SYNOPSIS

  package Manoc::DB::Result::Table;
  use parent 'DBIx::Class::';

  __PACKAGE__->load_components('+Manoc::DB::InflateColumn::IPv4);

  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type'    => 'VARCHAR',
      'size'         => 255,
      'ipv4_address' => 1
    }
  );

=cut

1;
