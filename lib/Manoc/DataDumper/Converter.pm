# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Converter;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Moose;
use Data::Dumper;
use Manoc::DB;
use Manoc::DataDumper::Converter::Converter_1000000;

sub get_converter {
    my ( $self, $release ) = @_;

    if ( $release eq '1.000000' ) {
        return Manoc::DataDumper::Converter::Converter_1000000->new();
    }
    return undef;
}

sub upgrade { }

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
