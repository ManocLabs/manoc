# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package App::Manoc::DataDumper::Converter::Base;

use Moose;
use Class::Load;

has 'log' => (
    is       => 'ro',
    required => 1,
);

has 'schema' => (
    is       => 'ro',
    required => 1,
);

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
