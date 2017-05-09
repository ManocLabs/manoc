package App::Manoc::Manifold;
#ABSTRACT: Manifold registry

use strict;
use warnings;

##VERSION

use namespace::clean;
use base qw(Class::Accessor::Grouped);
use Carp qw(croak);

use Module::Pluggable
    sub_name    => '_plugins',
    search_path => 'App::Manoc::Manifold',
    ;
use Class::Load qw(load_class);

__PACKAGE__->mk_group_accessors( inherited => 'name_mappings' );
__PACKAGE__->mk_group_accessors( inherited => 'manifold_list' );

=head1 METHODS

=cut

=head2 load_namespace

Loads all manifolds from App::Manoc::Manifold namespace

=cut

sub load_namespace {
    my $self      = shift;
    my @manifolds = $self->_plugins;

    my %mapping;
    foreach my $m (@manifolds) {
        $m =~ /App::Manoc::Manifold::(.+)/ and
            $mapping{$1} = $m;
    }
    $self->name_mappings( \%mapping );

    $self->manifold_list( \@manifolds );
}

=head2 manifolds

Return a list of the names of all known manifolds

=cut

sub manifolds {
    return keys( %{ shift->name_mappings } );
}

=head2 new_manifold($name)

Create a new instance of manifold $name.

=cut

sub new_manifold {
    my $self = shift;
    my $name = shift;

    defined( $self->name_mappings ) or
        $self->load_namespace;

    my $mapped = $self->name_mappings->{$name};
    $mapped or croak "Unknown manifold $name";

    load_class $mapped;
    return $mapped->new(@_);
}

=head2 connect($name)

Create a new instance of manifold $name and call its connect method.

=cut

sub connect {
    shift->new_manifold( shift, @_ )->connect();
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
