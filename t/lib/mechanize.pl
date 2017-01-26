$ENV{MANOC_SKIP_CSRF}      = 1;

$ENV{MANOC_SUPPRESS_LOG}   = 1
    unless $ENV{NO_SUPPRESS_LOG};

## Setup mech

unless ( eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1} ) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

use vars qw/ $Mech $ADMIN_USER $ADMIN_PASS /;

use Manoc::DB;
$ADMIN_USER = 'admin';
$ADMIN_PASS = $Manoc::DB::DEFAULT_ADMIN_PASSWORD;

ok( $Mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'Manoc' ),
    "Created mech object" );

sub mech_login {
    my $user = shift || $ADMIN_USER,
    my $pass = shift || $ADMIN_PASS,

    $Mech->get_ok( '/auth/login' );
    $Mech->text_contains( "Manoc login", "Make sure we are on the login page" );

    $Mech->submit_form_ok(
        {
            fields => {
                username   => $user,
                password   => $pass,
            },
        },
        'Submit login form',
    );
    $Mech->text_contains( "User: $admin", "Check user name in menubar" );

}

1;
