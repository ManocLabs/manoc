package App::Manoc::View::CSV;
#ABSTRACT: CSV view for Manoc

use strict;
use warnings;

##VERSION

use base qw ( Catalyst::View::CSV );

__PACKAGE__->config(
    sep_char => ",",
    binary   => 1,
);

=head1 SEE ALSO

L<App::Manoc>, L<Catalyst::View::CSV>, L<Text::CSV>

=cut

1;
