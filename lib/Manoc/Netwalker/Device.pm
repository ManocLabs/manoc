package Manoc::Netwalker::Device;
use Moose;

has 'entry' => (
    is       => 'ro',
    required => 1,
);

has 'source' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_source',
);

has 'switch_ports' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { return {} },
);

sub update_neighbors {

}

sub update_mat {
}

sub update_vtp {
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
