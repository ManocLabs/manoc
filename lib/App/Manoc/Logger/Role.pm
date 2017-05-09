package App::Manoc::Logger::Role;
#ABSTRACT: Role for Manoc logger

=head1 Description

This role adds a log attribute pointing to a L<App::Manoc::Logger> instance.

=cut

use Moose::Role;

##VERSION

use Log::Log4perl;
use App::Manoc::Logger;

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
        App::Manoc::Logger->initialized or die "Using unitialized logger";
    }
    return App::Manoc::Logger->logger( ref( $_[0] ) );
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
