unless ( eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1} ) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

use vars qw/ $User $Pass $Mech /;

ok( $Mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'Manoc' ),
    "Created mech object" );

# login credentials for all testing code
our $User = 'admin';
our $Pass = 'password';
