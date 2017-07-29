package App::Manoc::View::TT::Plugin::PP;
#ABSTRACT: Manoc Pretty print plugin for TT

use strict;
use warnings;

##VERSION

use base 'Template::Plugin';
use namespace::autoclean;

use Template::Plugin;
use Template::Filters;
use App::Manoc::Utils qw(check_mac_addr);

=head1 DESCRIPTION

Manoc TT plugin for pretty printing manoc objects

=head1 SYNOPSYS

    [% USE PP %]

    [% PP.manoc_print( row ) %]

=cut

=method new

Contructor.

=cut

sub new {
    my ( $class, $context, $params ) = @_;

    bless { _CONTEXT => $context, }, $class;
}

=method manoc_print($object [$params])

Pretty prints $object creating a link. Support model rows, Manoc IPv4 address
objects and mac address strings (e.g. "11:22:33:44:55:66").

Interfaces can be represented by hash, e.g.
{ device => $device_obj, iface => 'port'}.


=cut

sub manoc_print {
    my $self   = shift;
    my $object = shift;
    my $params = ref( $_[0] ) eq 'HASH' ? $_[0] : {};

    ref($object) or return $self->_manoc_print_scalar($object);
    ref($object) eq 'HASH' and return $self->_manoc_print_hash($object);

    # get context and Catalyst app
    my $ctx = $self->{_CONTEXT};
    my $c   = $ctx->stash->get('c');

    my $url = $c->manoc_uri_for_object($object);
    if ( !defined($url) ) {
        $c->log->error("Cannot get URL for object $object");
        return;
    }

    my $label;
    if ( $object->can('name') ) {
        $label = $object->name;
    }
    elsif ( $object->can('label') ) {
        $label = $object->label;
    }
    elsif ( $object->isa('App::Manoc::IPAddress::IPv4') ) {
        $label = $object->unpadded;
    }

    if ( !defined($label) ) {
        $c->log->error("Cannot get label for object $object");
        return;
    }

    return _print_link( $label, $url );
}

sub _manoc_print_scalar {
    my ( $self, $object ) = @_;

    # get context and Catalyst app
    my $ctx = $self->{_CONTEXT};
    my $c   = $ctx->stash->get('c');

    if ( check_mac_addr($object) ) {
        my $url = $c->uri_for_action( 'mac/view', $object );
        return _print_link( $object, $url );
    }

    return $object;
}

sub _manoc_print_hash {
    my ( $self, $object ) = @_;

    # get context and Catalyst app
    my $ctx = $self->{_CONTEXT};
    my $c   = $ctx->stash->get('c');

    # an interface light object
    if ( $object->{iface} && $object->{device} ) {
        my $iface  = $object->{iface};
        my $device = $object->{device};
        my $url    = $c->uri_for_action( 'interface/view',
            [ $device->id, Template::Filters::uri_filter($iface) ] );
        return _print_link( $iface, $url );
    }
}

sub _print_link() {
    my ( $label, $url ) = @_;
    $label = Template::Filters::html_filter($label);
    return "<a href=\"$url\">$label</a>";
}

=head1 SEE ALSO

L<App::Manoc>

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
