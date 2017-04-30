package App::Manoc::View::CSV;

use base qw ( Catalyst::View::CSV );
use strict;
use warnings;

__PACKAGE__->config(
    sep_char => ",",
    binary   => 1,
);

=head1 NAME

App::Manoc::View::CSV - CSV view for Manoc

=head1 DESCRIPTION

CSV view for Manoc

=head1 SEE ALSO

L<Manoc>, L<Catalyst::View::CSV>, L<Text::CSV>

=head1 AUTHOR

Gabriele

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
