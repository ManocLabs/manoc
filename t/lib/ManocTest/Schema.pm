package ManocTest::Schema;
use strict;
use warnings;

use base qw( Manoc::DB );

sub connection {
    my $self = shift;

    my $db_file = 'var/test.db';

    unlink($db_file) if -e $db_file;
    unlink($db_file . '-journal') if -e $db_file . '-journal';
    mkdir("var") unless -d "var";


    my $dsn = "dbi:SQLite:$db_file";
    my $schema = $self->next::method(
	$dsn, '', '',
	{ AutoCommit => 1,
	  on_connect_do => sub {
	      my $storage = shift;
	      my $dbh = $storage->_get_dbh;

	      # no fsync on commit
	      $dbh->do ('PRAGMA synchronous = OFF');
	  }
      });


    my $dbh = $schema->storage->dbh;
    $schema->deploy();

    $self->load_fixtures($schema);

    return $schema;
}

sub load_fixtures {
    my $self = shift;
    my $schema = shift;
    
    local $schema->storage->{debug}
	if ($ENV{TRAVIS}||'') eq 'true';

    $schema->populate('Role', [
	[ qw/id role/ ],
	[ qw/1 admin / ],
    ]);
    
    # admin_user
    $schema->resultset('User')->update_or_create(
        {
            username => 'admin',
            fullname => 'Administrator',
            active   => 1,
            password => 'password',
        }
    );
    $schema->populate('UserRole', [
		      [ qw/role_id user_id/ ],
		      [ qw/1 1/ ]
		  ] );
    
    $schema->populate('Building', [
	[qw/id name description/],
	[qw/1  B01/,  "Building 1"],
    ]);

}

1;
