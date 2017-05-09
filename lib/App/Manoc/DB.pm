package App::Manoc::DB;
#ABSTRACT: Manoc DB Schema

use strict;
use warnings;

##VERSION

=head1 DESCRIPTION

Manoc DB Schema extends C<DBIx::Class::Schema>.

It also loads the required L<DBIx::Class::Helper> components and
provides methods for schema configuration and initialization.

=cut

our $SCHEMA_VERSION = 4;

our $DEFAULT_ADMIN_PASSWORD = 'admin';

use parent 'DBIx::Class::Schema';

__PACKAGE__->load_components(
    qw(
        Helper::Schema::LintContents
        Helper::Schema::QuoteNames
        Helper::Schema::DidYouMean

        Helper::Schema::Verifier::ColumnInfo
        Helper::Schema::Verifier::RelationshipColumnName
        Helper::Schema::Verifier::Parent
        )
);

__PACKAGE__->load_namespaces( default_resultset_class => '+App::Manoc::DB::ResultSet', );

=method allowed_column_keys

This method is overriden from
C<DBIx::Class::Helper::Schema::Verifier::ColumnInfo> to add some
non-standard confg keys used by Manoc

=cut

sub allowed_column_keys {
    my $self = shift;
    my @keys = $self->next::method;
    push @keys, qw(encode_class encode_check_method encode_args encode_column
        ipv4_address
        extras
        _inflate_info);
    return @keys;
}

=function base_result

Return C<'App::Manoc::DB::Result'>

=cut

sub base_result { 'App::Manoc::DB::Result' }

=function base_resultset

Return C<'App::Manoc::DB::ResultSet'>

=cut

sub base_resultset { 'App::Manoc::DB::ResultSet' }

=function get_version

Return the current schema version. Used tools like datadumper.

=cut

sub get_version {
    return $SCHEMA_VERSION;
}

our $DEFAULT_CONFIG = {
    connect_info => {
        dsn      => $ENV{MANOC_DB_DSN}      || 'dbi:SQLite:manoc.db',
        user     => $ENV{MANOC_DB_USERNAME} || undef,
        password => $ENV{MANOC_DB_PASSWORD} || undef,

        # dbi_attributes
        quote_names => 1,

        # extra attributes
        AutoCommit => 1,
    },
};

=method init_admin

Create or reset admin user.

=cut

sub init_admin {
    my ($self) = @_;

    my $admin_user = $self->resultset('User')->update_or_create(
        {
            username   => 'admin',
            fullname   => 'Administrator',
            active     => 1,
            password   => $DEFAULT_ADMIN_PASSWORD,
            superadmin => 1,
            agent      => 0,
        }
    );
}

=method init_vlan

When there is no defined VlanRange create a sample range with a sample
vlan.

=cut

sub init_vlan {
    my ($self) = @_;

    my $rs = $self->resultset('VlanRange');
    if ( $rs->count() > 0 ) {
        return;
    }
    my $vlan_range = $rs->update_or_create(
        {
            name        => 'sample',
            description => 'sample range',
            start       => 1,
            end         => 10,
        }
    );
    $vlan_range->add_to_vlans( { name => 'native', id => 1 } );
}

=method init_ipnetwork

Whene there is no defined IPNetwork rows create some sample networks
and subnetworks.

=cut

sub init_ipnetwork {
    my ($self) = @_;

    my $rs = $self->resultset('IPNetwork');

    $rs->count() > 0 and return;
    $rs->update_or_create(
        {
            address => App::Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 16,
            name    => 'My Corp network'
        }
    );
    $rs->update_or_create(
        {
            address => App::Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 22,
            name    => 'Server Farm'
        }
    );
    $rs->update_or_create(
        {
            address => App::Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 24,
            name    => 'Yellow zone'
        }
    );
    $rs->update_or_create(
        {
            address => App::Manoc::IPAddress::IPv4->new("10.10.0.0"),
            prefix  => 24,
            name    => 'Yellow zone'
        }
    );
    $rs->update_or_create(
        {
            address => App::Manoc::IPAddress::IPv4->new("10.10.1.0"),
            prefix  => 24,
            name    => 'Green zone'
        }
    );
    $rs->update_or_create(
        {
            address => App::Manoc::IPAddress::IPv4->new("10.10.5.0"),
            prefix  => 23,
            name    => 'Workstations'
        }
    );
}

=method init_roles

Populate Role rows based on Manoc default roles defined in L<App::Manoc::CatalystRole::Permission>

=cut

sub init_roles {
    my ( $self, $conf_roles ) = @_;

    my $rs = $self->resultset('Role');

    my $default_roles = \%App::Manoc::CatalystRole::Permission::DEFAULT_ROLES;
    my $roles = Catalyst::Utils::merge_hashes( $default_roles, $conf_roles );

    foreach my $role ( keys %$roles ) {
        $rs->update_or_create( { role => $role } );
    }

}

=method init_management_url

Create some sample MngUrlFormat rows.

=cut

sub init_management_url {
    my ($self) = @_;
    my $rs = $self->resultset('MngUrlFormat');
    $rs->update_or_create(
        {
            name   => 'telnet',
            format => 'telnet:%h',
        }
    );
    $rs->update_or_create(
        {
            name   => 'ssh',
            format => 'ssh:%h',
        }
    );
    $rs->update_or_create(
        {
            name   => 'http',
            format => 'http://:%h',
        }
    );
    $rs->update_or_create(
        {
            name   => 'https',
            format => 'https://:%h',
        }
    );
}

1;
