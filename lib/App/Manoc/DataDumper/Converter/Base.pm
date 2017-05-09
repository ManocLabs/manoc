package    # hide form CPAN
    App::Manoc::DataDumper::Converter::Base;

use Moose;

##VERSION

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
