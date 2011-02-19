# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Logger::CatalystRole;
use Moose::Role;

use Manoc::Logger;
use Log::Log4perl::Catalyst;

sub setup_log {
    my ( $class, $levels ) = @_;

    return if $class->log;

    $levels ||= '';
    $levels =~ s/^\s+//;
    $levels =~ s/\s+$//;
    my %levels = map { $_ => 1 } split /\s*,\s*/, $levels;

    my $env_debug = Catalyst::Utils::env_value( $class, 'DEBUG' );
    if ( defined $env_debug ) {
        $levels{debug} = 1 if $env_debug;    # Ugly!
        delete( $levels{debug} ) unless $env_debug;
    }

    Manoc::Logger->init(
        {
            class => $class,
            debug => $levels{debug}
        }
    );

    # start default screen logger
    $class->log( Log::Log4perl::Catalyst->new() );

    # ovverride debug method
    if ( $levels{debug} ) {
        Class::MOP::get_metaclass_by_name($class)->add_method( 'debug' => sub { 1 } );
        $class->log->debug('Debug messages enabled');
    }
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
