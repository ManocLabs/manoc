# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::ReportArchive;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);
__PACKAGE__->table('report_archive');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64,
    },
    timestamp => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    type => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32,
    },
    s_class => {
        data_type   => 'text',
        is_nullable => 0,
    }
);

__PACKAGE__->inflate_column(
    's_class',
    {
        inflate => sub {
            my $class = "Manoc::Report::" . $_[1]->type;

            # hack stolen from catalyst:
            # don't overwrite $@ if the load did not generate an error
            my $error;
            {
                local $@;
                my $file = $class . '.pm';
                $file =~ s{::}{/}g;
                eval { CORE::require($file) };
                $error = $@;
            }
            die $error if $error;

            $class->thaw( $_[0] );
        },
        deflate => sub { $_[0]->freeze },
    }
);

__PACKAGE__->set_primary_key('id');

=head1 NAME

Manoc::DB::Result::ReportArchive - <   >


=cut

1;
