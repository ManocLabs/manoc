# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::View::TT::Plugin::Menu;

use strict;
use warnings;

use Template::Plugin;
use base 'Template::Plugin';

=head1 NAME

Manoc::View::TT::Plugin::JSON - Manoc menu plugin

=head1 DESCRIPTION

Manoc TT plugin to generate application navigation menu

=cut

my @DEFAULT_MENU_ITEMS = (
    {
        name  => 'Network',
        items => [
            {
                name   => 'Devices',
                action => '/device/list',
            },
            {
                separator => 1,
            },
            {
                name   => 'IP Address Plan',
                action => '/ipnetwork/list',
            },
            {
                name   => 'VLAN',
                action => '/vlanrange/list',
            },
            {
                name => 'WLAN',
                path => '#',
            },
        ],
    },
    {
        name  => 'Server',
        items => [
            {
                name   => 'Servers',
                action => '/server/list',
            },
            {
                separator => 1,
            },
            {
                name   => 'Virtual Infrastructures',
                action => '/virtualinfr/list',
            },
            {
                name   => 'Virtual Machines',
                action => '/virtualmachine/list',
            },
            {
                name   => 'Hypervisors',
#                action => '/server/hypervisors',
            },

        ]
    },
    {
        name  => 'Assets',
        items => [
            {
                name   => 'Complete Inventory',
                action => '/hwasset/list',
            },
            {
                name   => 'Server Hardware',
                action => '/serverhw/list',
            },
            {
                name   => 'Device Hardware',
                action => '/hwasset/devices',
            },
            {
                separator => 1,
            },
            {
                name   => 'Buildings',
                action => '/building/list',
            },
            {
                name   => 'Racks',
                action => '/rack/list',
            },

        ]
    },

    {
        name  => 'Config',
        items => [
            {
                name       => 'Users',
                action     => '/user/list',
                permission => 'user.view',
            },
            {
                name       => 'Groups',
                action     => '/group/list',
                permission => 'group.view',
            },
            {
                name       => 'Management Urls',
                action     => '/mngurlformat/list',
                permission => 'mngurlformat.view',
            },
        ]
    }
);

sub new {
    my ( $class, $context, $params ) = @_;

    bless { _CONTEXT => $context, }, $class;
}

sub menu {
    my $self = shift;
    my $ctx  = $self->{_CONTEXT};

    # get Catalyst app
    my $c = $ctx->stash->get('c');

    my @menu;
    foreach my $item (@DEFAULT_MENU_ITEMS) {

        my $subitems = $item->{items};
        if ( defined($subitems) ) {

            my @new_subitems =
                map { _expand_item( $c, $_ ) }
                grep { _permission_check( $c, $_ ) } @$subitems;

            # do not add empty items
            next unless scalar(@new_subitems);

            $item->{items} = \@new_subitems;

        }
        _expand_item( $c, $item );
        push @menu, $item;
    }
    return @menu;
}

sub _permission_check {
    my ( $c, $item ) = @_;

    $item->{permission} or return 1;

    return $c->check_permission( $item->{permission} );
}

sub _expand_item {
    my ( $c, $item ) = @_;

    $item->{action} and
        $item->{path} = $c->uri_for_action( $item->{action} );

    return $item;
}

=head1 SEE ALSO

L<Manoc>

=head1 AUTHOR

gabriele

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
