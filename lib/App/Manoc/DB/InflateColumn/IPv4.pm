package App::Manoc::DB::InflateColumn::IPv4;
#ABSTRACT: Inflator for IP v4 addresses

use strict;
use warnings;

##VERSION

use parent 'DBIx::Class';

use App::Manoc::IPAddress::IPv4;

sub register_column {
    my $self = shift;
    my ( $column, $info, $args ) = @_;
    $self->next::method(@_);

    return unless $info->{'ipv4_address'};

    $self->inflate_column(
        $column => {
            inflate => \&inflate_ipv4_column,
            deflate => \&deflate_ipv4_column,
        }
    );
}

sub inflate_ipv4_column {
    my ( $value, $obj ) = @_;
    return App::Manoc::IPAddress::IPv4->new($value) if defined($value);
}

sub deflate_ipv4_column {
    my ( $value, $obj ) = @_;
    return $value->padded if defined($value);
}

=head1 SYNOPSIS

  package App::Manoc::DB::Result::Table;
  use parent 'DBIx::Class';

  __PACKAGE__->load_components('+App::Manoc::DB::InflateColumn::IPv4);

  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type'    => 'VARCHAR',
      'size'         => 255,
      'ipv4_address' => 1
    }
  );

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
