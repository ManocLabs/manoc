package ManocTest;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(
    init_manoctest get_mech mech_login
);

# Include our application dir
use File::Spec;
# needed to load the conf
use ManocTest::Schema;

use File::Basename;
use File::Spec;

use Test::More;

use Manoc::DB;
our $ADMIN_USER = 'admin';
our $ADMIN_PASS = $Manoc::DB::DEFAULT_ADMIN_PASSWORD;

sub init_manoctest {

    my $lib = dirname( $INC{"ManocTest.pm"} );
    my $config_file = File::Spec->catfile( $lib, "manoc_test.conf" );
    -f $config_file or
        BAIL_OUT "Can't find config file $config_file";

    $ENV{LANG}            = 'C';
    $ENV{CATALYST_CONFIG} = $config_file;

    $ENV{MANOC_SKIP_CSRF}    = 1;
    $ENV{MANOC_SUPPRESS_LOG} = 1
        unless $ENV{NO_SUPPRESS_LOG};
}

my $Mech;

sub get_mech {
    $Mech and return $Mech;

    ## Setup mechanize
    unless ( eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1} ) {
        plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
        exit 0;
    }

    ok( $Mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'Manoc' ),
        "Created mech object" );

    return $Mech;
}

sub mech_login {
    my $user = shift || $ADMIN_USER, my $pass = shift || $ADMIN_PASS,

        my $mech = get_mech;

    $mech->get_ok('/auth/login');
    $mech->text_contains( "Manoc login", "Make sure we are on the login page" );

    $mech->submit_form_ok(
        {
            fields => {
                username => $user,
                password => $pass,
            },
        },
        "Submit login form $user:$pass",
    );
    $mech->text_contains( "User: $user", "Check user name in menubar" );

    return $mech;
}

1;
