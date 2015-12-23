# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Manifold;

use strict;
use warnings;
use namespace::clean;
use base qw(Class::Accessor::Grouped);
use Carp qw(croak);

use Module::Pluggable
    sub_name    => '_plugins',
    search_path => 'Manoc::Manifold',
    ;
use Class::Load qw(load_class);

__PACKAGE__->mk_group_accessors( inherited => 'name_mappings' );
__PACKAGE__->mk_group_accessors( inherited => 'manifold_list' );

sub load_namespace {
    my $self      = shift;
    my @manifolds = $self->_plugins;

    my %mapping;
    foreach my $m (@manifolds) {
        $m =~ /Manoc::Manifold::(.+)/ and
            $mapping{$1} = $m;
    }
    $self->name_mappings( \%mapping );

    $self->manifold_list( \@manifolds );
}

sub manifolds {
    return keys( %{ shift->name_mappings } );
}

sub new_manifold {
    my $self = shift;
    my $name = shift;

    defined( $self->name_mappings ) or
        $self->load_namespace;

    my $mapped = $self->name_mappings->{$name};
    $mapped or croak "Unknown manifold $name";

    load_class $mapped;
    return $mapped->new(@_);
}

sub connect {
    shift->new_manifold( shift, @_ )->connect();
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
