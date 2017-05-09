package App::Manoc::View::CSV;
#ABSTRACT: CSV Catalyst view for Manoc

use strict;
use warnings;

##VERSION

=head1 DESCRIPTION

C<Catalyst::View::CSV>

=cut

use base qw ( Catalyst::View::CSV );

__PACKAGE__->config(
    sep_char => ",",
    binary   => 1,
);

=head1 SEE ALSO

L<App::Manoc>, L<Catalyst::View::CSV>, L<Text::CSV>

=cut

1;
