use strict;
use warnings;
use Test::More;

BEGIN {
    use FindBin;
    require "$FindBin::Bin/lib/inc.pl";
}   

BEGIN { use_ok 'Manoc::Controller::Auth' }
{
    content_like( '/auth/login', qr'<form[^>]+login_form', 'Login form' );
}
{     
    my $req = POST '/auth/login', [ username => 'admin' , password => 'password' ];
    ok($req, 'Login URL good credentials');

    my ($res, $c) = ctx_request( $req );
    ok( $res->is_redirect,   "Redirected to home page" );
}

{
    my $req = POST '/auth/login', [ username => 'admin' , password => 'badpassword' ];
    ok($req, 'Login URL bad credentials');

    my ($res, $c) = ctx_request( $req );
    ok( $res->is_success,   "Request succeeded" );
    ok( $res->content =~ /login_form/, "Login form redisplayed");
}

done_testing();