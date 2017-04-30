package App::Manoc::DB::Result::Session;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('sessions');
__PACKAGE__->add_columns(
    'id' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 72,
    },
    'session_data' => { data_type => 'text', },
    'expires'      => {
        data_type => 'int',
        size      => 10,
    }
);

__PACKAGE__->set_primary_key(qw(id));

=head1 NAME

App::Manoc::DB::Result::Session - A model object representing a WEB UI session

=head1 DESCRIPTION

Needed for L<CGI::Session> L<CGI::Session::Driver::dbixc>

=cut

1;
