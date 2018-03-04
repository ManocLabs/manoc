package App::Manoc::CatalystRole::ObjectURL;
#ABSTRACT: Catalyst plugin for Manoc CSRF support

use Moose;

##VERSION
use namespace::autoclean;
with 'Catalyst::ClassData';

use Scalar::Util qw(blessed);

__PACKAGE__->mk_classdata( '_manoc_object_action' => {} );

=method setup_finalize

Register to Catalyst setup_finalize in order to scan all registered controllers
for controller->resultset mapping.

=cut

sub setup_finalize {
    my $app = shift;
    $app->next::method(@_);

    foreach my $name ( $app->controllers ) {
        my $controller = $app->controller($name);
        if ( $controller->can('class') && $controller->can('view') ) {
            my $class = $controller->class;
            $class =~ /^ManocDB::(.*)$/ or next;
            my $rs = $1;
            my $ns = $controller->action_namespace();
            # $app->debug and $app->log->debug("Registered $ns/view for rs $rs");
            $app->_manoc_object_action->{$rs} = "$ns/view";
        }
    }
}

=method  manoc_uri_for_object( $c, $obj, @args )

Finds (if any) the controller which has the view action for obj and call
uri_for_action( "controller/view", [$obj->id], @args)

=cut

sub manoc_uri_for_object {
    my ( $c, $obj, @args ) = @_;

    blessed($obj) or return;

    if ( $obj->isa("App::Manoc::IPAddress::IPv4") ) {
        return $c->uri_for_action( 'ipaddress/view', [ $obj->address ] );
    }

    if ( $obj->can('result_source') ) {
        my $name = $obj->result_source->source_name;
        # $c->log->debug("Lookup action for source $name");
        my $action = $c->_manoc_object_action->{$name};
        $action and
            return $c->uri_for_action( $action, [ $obj->id ], @args );
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
