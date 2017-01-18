## Configure manoc via ENV

# default login credentials for all testing code
$ENV{MANOC_TEST_USER} = 'admin';
$ENV{MANOC_TEST_PASS} = 'password';

$ENV{MANOC_SKIP_CSRF} = 1;
$ENV{MANOC_TEST_AUTOLOGIN} = 1;

$ENV{MANOC_SUPPRESS_LOG} = 1
    unless $ENV{NO_SUPPRESS_LOG};

## Setup mech

unless ( eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1} ) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

use vars qw/ $Mech /;

ok( $Mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'Manoc' ),
    "Created mech object" );


1;
