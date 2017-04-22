# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::View::TT::Plugin::Menu;

use strict;
use warnings;

use Template::Plugin;
use base 'Template::Plugin';
use namespace::autoclean;

=head1 NAME

Manoc::View::TT::Plugin::JSON - Manoc menu plugin

=head1 DESCRIPTION

Manoc TT plugin to generate application navigation menu

=cut

my @DEFAULT_MENU_ITEMS = (
    {
        name    => 'Network',
        fa_icon => 'globe',
        submenu => [
            {
                name   => 'Devices',
                action => '/device/list',
            },
            {
                name    => 'IP Address Plan',
                submenu => [
                    {
                        name   => "All IP Networks",
                        action => 'ipnetwork/list',
                    },
                    {
                        name   => "Top level IP Networks",
                        action => 'ipnetwork/root',
                    },
                    {
                        name   => "IP Blocks",
                        action => 'ipblock/list',
                    },
                ]
            },
            {
                name    => 'VLAN',
                submenu => [
                    {
                        name   => "VLAN by range",
                        action => 'vlanrange/list',
                    },
                    {
                        name   => "VTP list",
                        action => 'vtp/list',
                    },
                    {
                        name   => "Compare with VTP",
                        action => 'vtp/compare',
                    },
                ]
            },
            {
                name => 'WLAN',
                path => '#',
            },
            {
                name   => 'DHCP Servers',
                action => '/dhcpserver/list',
            },
        ],
    },
    {
        name    => 'Servers',
        fa_icon => 'server',
        submenu => [
            {
                name   => 'Server List',
                action => '/server/list',
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
                name => 'Hypervisors',
                path => '#',
                # action => '/server/hypervisors',
            }
        ]
    },
    {
        name    => 'Hosts',
        fa_icon => 'desktop',
        submenu => [
            {
                name   => 'Workstation',
                action => '/workstation/list',
            },
        ]
    },
    {
        name    => 'Inventory',
        fa_icon => 'list',
        submenu => [
            {
                name   => 'All Hardware',
                action => '/hwasset/list',
            },
            {
                name   => 'Device Hardware',
                action => '/hwasset/list_devices',
            },
            {
                name   => 'Server Hardware',
                action => '/serverhw/list',
            },
            {
                name   => 'Workstation Hardware',
                action => '/workstationhw/list',
            },
            {
                name   => 'Installed Software',
                action => '/softwarepkg/list'
            },
        ],
    },
    {
        name    => 'Premises',
        fa_icon => 'building',
        submenu => [
            {
                name   => 'Buildings',
                action => '/building/list',
            },
            {
                name   => 'Racks',
                action => '/rack/list',
            },
            {
                name   => 'Warehouses',
                action => '/warehouse/list',
            },
        ]
    },
    {
        name    => 'Config',
        fa_icon => 'cogs',
        submenu => [
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

    return process_menu( $c, @DEFAULT_MENU_ITEMS );
}

sub process_menu {
    my $c    = shift;
    my @menu = @_;

    my @result;

    foreach my $item (@menu) {
        my $new_item = {};

        _permission_check( $c, $item ) or next;

        $new_item->{name}    = $item->{name};
        $new_item->{icon}    = $item->{icon};
        $new_item->{fa_icon} = $item->{fa_icon};

        if ( $item->{action} ) {
            $new_item->{path} = $c->uri_for_action( $item->{action} );
        }
        else {
            $new_item->{path} = $item->{path};
        }

        if ( $item->{submenu} ) {
            my @submenu = process_menu( $c, @{ $item->{submenu} } );
            next unless @submenu;
            $new_item->{submenu} = \@submenu;
        }

        push @result, $new_item;
    }
    return @result;
}

sub _permission_check {
    my ( $c, $item ) = @_;

    $item->{permission} or return 1;
    return $c->user && $c->check_permission( $item->{permission} );
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
