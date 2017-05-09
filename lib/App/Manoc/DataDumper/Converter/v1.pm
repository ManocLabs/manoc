package    # Hide from CPAN
    App::Manoc::DataDumper::Converter::v1;

use Moose;

##VERSION

extends 'App::Manoc::DataDumper::Converter::Base';

use Data::Dumper;

# check for spurious data
sub upgrade_winlogon {
    my ( $self, $data ) = @_;
    my $count = 0;
    my ( $i, $name );
    return 0 unless ( defined($data) );

    for ( $i = 0; $i < scalar( @{$data} ); $i++ ) {
        $name = $data->[$i]->{'user'};
        if ( $name =~ m/^\W$/ ) {
            $count++;
            splice( @{$data}, $i, 1 );
        }
    }
    return $count;
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();
1;
