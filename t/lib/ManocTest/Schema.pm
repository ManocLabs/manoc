package ManocTest::Schema;
use strict;
use warnings;

use base qw( Manoc::DB );

=head1 NAME

ManocTest::Schema - Library to be used by manoc test scripts.

=cut


sub connection {
    my $self = shift;

    my $db_file = ':memory:';
    my $dsn     = "dbi:SQLite:$db_file";

    my $schema = $self->next::method(
        $dsn, '', '',
        {
            AutoCommit    => 1,
            on_connect_do => sub {
                my $storage = shift;
                my $dbh     = $storage->_get_dbh;

                # no fsync on commit
                $dbh->do('PRAGMA synchronous = OFF');
            }
        }
    );

    my $dbh = $schema->storage->dbh;
    $schema->deploy();

    $self->load_test_fixtures($schema) unless
        $ENV{MANOC_TEST_NOFIXTURES};

    return $schema;
}

sub load_test_fixtures {
    my $self   = shift;
    my $schema = shift;

    $schema->init_admin;
}


# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

1;
