package App::Manoc::DB::Result::SoftwarePkg;
#ABSTRACT: A model object representing a software package name the system.

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('software_pkg');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['name'] );

__PACKAGE__->has_many(
    server_swpkg => 'App::Manoc::DB::Result::ServerSWPkg',
    'software_pkg_id'
);

__PACKAGE__->many_to_many( servers => 'server_swpkg', 'server' );

=method count_servers_by_version

Return the number of server using this software, grouped by version.
Returned columns are version and n_servers.

=cut

sub count_servers_by_version {
    my $self = shift;

    my $rs = $self->server_swpkg->search(
        {},
        {
            select => [
                'version',
                {
                    count => 'server_id',
                }
            ],
            as       => [qw/ version n_servers /],
            group_by => ['version'],
        }
    );
    return wantarray ? $rs->all : $rs;
}

1;
