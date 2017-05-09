package App::Manoc::View::TT;

use strict;
use warnings;

##VERSION

use base 'Catalyst::View::TT';

use App::Manoc;

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH       => [
        App::Manoc->path_to( 'root', 'src' ),
        App::Manoc->path_to( 'root', 'src', 'include' ),
        App::Manoc->path_to( 'root', 'src', 'pages' ),
    ],
    PRE_PROCESS => 'init.tt',
    WRAPPER     => 'wrapper.tt',
    PLUGIN_BASE => 'App::Manoc::View::TT::Plugin',
    render_die  => 1,
);

=head1 NAME

App::Manoc::View::TT - TT View for Manoc

=head1 DESCRIPTION

This is the Template Toolkit view for Manoc.

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
