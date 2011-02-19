# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Logger::Role;

use 5.008;
use Moose::Role;
use Log::Log4perl;

has 'log' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_log'
);

sub _build_log {
    my $self = shift;

    if ( $self->can('_init_logging') ) {
        $self->_init_logging;
    }
    else {
        Manoc::Logger->initialized or die "Using unitialized logger";
    }
    return Manoc::Logger->logger( ref( $_[0] ) );
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
