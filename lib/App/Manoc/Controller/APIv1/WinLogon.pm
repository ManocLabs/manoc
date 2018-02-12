package App::Manoc::Controller::APIv1::WinLogon;
#ABSTRACT: Controller for WinLogon APIs

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'App::Manoc::ControllerBase::APIv1' }

=action base

=cut

sub base : Chained('deserialize') PathPart('winlogon') CaptureArgs(0) {
    return;
}

=action winlogon_post

POST api/v1/winlogon

=cut

sub winlogon_post : Chained('base') PathPart('') Args(0) POST {
    my ( $self, $c ) = @_;

    $c->stash(
        api_validate => {
            type  => 'hash',
            items => {
                user => {
                    type     => 'scalar',
                    required => 1,
                },
                ipaddr => {
                    type     => 'scalar',
                    required => 1,
                },
            }
        }
    );
    $c->forward('validate') or return;

    my $req_data = $c->stash->{api_request_data};

    my $user   = $req_data->{user};
    my $ipaddr = $req_data->{ipaddr};

    if ( !check_addr($ipaddr) ) {
        $c->stash( api_field_errors => [ { ipaddr => "Not a valid address" } ] );
        return;
    }
    $ipaddr = App::Manoc::IPAddress::IPv4->new($ipaddr);

    my $rs;
    if ( $user =~ /([^\$]+)\$$/ ) {
        $user = $1;
        $rs   = $c->model('ManocDB::WinHostname');
    }
    else {
        $rs = $c->model('ManocDB::WinLogon');
    }

    $rs->register_tuple(
        user   => lc($user),
        ipaddr => $ipaddr,
    );
    my $data = { message => "entry registered", };
    $c->stash( api_response_data => $data );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
