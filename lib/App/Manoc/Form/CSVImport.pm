package App::Manoc::Form::CSVImport;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'HTML::FormHandler';
with
    'App::Manoc::Form::TraitFor::Theme',
    'App::Manoc::Form::TraitFor::CSRF';

use Text::CSV;
use Try::Tiny;

#required for CSRF
has '+ctx' => ( required => 1, );

has '+enctype' => ( default => 'multipart/form-data' );

has_field 'file' => (
    type     => 'Upload',
    max_size => '2000000',
    required => 1,
);

has_field 'save' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', 'btn-primary' ] },
    widget_wrapper => 'None',
    value          => "Upload",
);

has 'resultset' => (
    is       => 'rw',
    required => 1
);

has 'required_columns' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1,
);

has 'optional_columns' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'column_names' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

has 'optional_columns' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'lookup_columns' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'csv_lookup_columns' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_csv_lookup_columns'
);

has 'csv_mapped_columns' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_mapped_columns',
);

has 'csv_to_db_map' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_csv_to_db_map',
);

has 'csv_column_names' => (
    is  => 'rw',
    isa => 'ArrayRef',
);

has 'row_messages' => (
    is      => 'rw',
    isa     => 'ArrayRef[App::Manoc::Form::CSVImport::RowImportInfo]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        all_row_messages => 'elements',
        add_row_message  => 'push',
    }
);

has 'current_row_number' => (
    traits  => ['Number'],
    is      => 'rw',
    isa     => 'Num',
    default => 2,
    handles => {
        add_to_current_row_number => 'add'
    }
);

sub _build_csv_lookup_columns {
    my $self = shift;

    # support unique columns
    my $mapped_columns = $self->csv_mapped_columns;

    my @lookup_columns;

    for my $colset ( $self->lookup_columns ) {
        my @columns = ref($colset) eq 'ARRAY' ? @$colset : ($colset);

        # check for matching columns in the csv, if there is any missing skip to next constraint
        my @csv_columns = grep { $mapped_columns->{$_} } @columns;
        next unless @columns == @csv_columns;

        push @lookup_columns, \@columns;
    }

    return \@lookup_columns;
}

sub _build_csv_to_db_map {
    my $self = shift;

    my @all_columns = ( @{ $self->required_columns }, @{ $self->optional_columns } );

    # populate column names mapping
    my %csv2db_name;
    foreach my $csv_col ( @{ $self->csv_column_names } ) {
        print STDERR "checking $csv_col\n";
        if ( $csv_col ~~ @all_columns || lc($csv_col) ~~ @all_columns ) {
            $csv2db_name{$csv_col} = $csv_col;
            next;
        }
        if ( exists $self->column_names->{$csv_col} ) {
            $csv2db_name{$csv_col} = $self->column_names->{$csv_col};
            next;
        }
        if ( exists $self->column_names->{ lc($csv_col) } ) {
            $csv2db_name{$csv_col} = $self->column_names->{ lc($csv_col) };
            next;
        }
        # column is unknown, will be skipped
    }

    # use Data::Dumper;
    # print STDERR Dumper( $self->csv_column_names, \%csv2db_name );

    return \%csv2db_name;
}

sub _build_mapped_columns {
    my $self = shift;
    my %mapped_columns = map { $_ => 1 } values %{ $self->csv_to_db_map };
    return \%mapped_columns;
}

sub update_model {
    my $self = shift;

    my $csv = Text::CSV->new( { binary => 1 } );
    my $fh = $self->value->{file}->fh;

    # get column names from headers
    my $csv_column_names = $csv->getline($fh);
    if ( $csv->eof ) {
        $self->add_form_error('Error reading csv');
        return;
    }
    if ( !@$csv_column_names ) {
        $self->add_form_error('No row headers in csv file');
        return;
    }
    $csv->column_names($csv_column_names);
    $self->csv_column_names($csv_column_names);

    # check required columns
    my $mapped_columns = $self->csv_mapped_columns;
    foreach my $col ( @{ $self->required_columns } ) {
        $col ~~ %$mapped_columns and next;
        $self->add_form_error("row '$col' not found");
    }
    $self->has_errors and return;

    # slurp CSV file
    my $csv_rows = $csv->getline_hr_all($fh);
    if ( !$csv->eof ) {
        $self->add_form_error( "Error reading file (" . $csv->error_diag() . ")" );
        return;
    }
    close $fh;

    my $rs          = $self->resultset;
    my $csv2db_name = $self->csv_to_db_map;

    # process rows
    foreach my $csv_row (@$csv_rows) {

        # translate column names
        my %row = map { $csv2db_name->{$_} => $csv_row->{$_} } keys %$csv_row;

        # pre check
        if ( !$self->check_row( \%row ) ) {
            $self->add_to_current_row(1);
            next;
        }

        my $entry = $self->find_entry( \%row );
        $entry //= $rs->new_result( {} );

        # set columns
        foreach my $col ( @{ $self->required_columns } ) {
            $entry->$col( $row{$col} );
        }
        foreach my $col ( @{ $self->optional_columns } ) {
            next unless exists( $row{$col} );
            $entry->$col( $row{$col} );
        }

        try {
            my $message;
            if ( $entry->in_storage ) {
                $entry->update;
                $message = "Updated entry";
            }
            else {
                $entry->insert;
                $message = "Created new entry";
            }
            $self->add_row_message(
                App::Manoc::Form::CSVImport::RowImportInfo->new(
                    status     => 'success',
                    row_number => $self->current_row_number,
                    message    => $message,
                )
            );

        }
        catch {
            $self->add_row_message(
                App::Manoc::Form::CSVImport::RowImportInfo->new(
                    status     => 'error',
                    row_number => $self->current_row_number,
                    message    => "Error $_",
                )
            );
        };

        $self->add_to_current_row_number(1);
    }
}

sub check_row {
    my ( $self, $row ) = @_;
    return 1;
}

sub find_entry {
    my ( $self, $data ) = @_;

    my $rs = $self->resultset;

    foreach my $colset ( @{ $self->csv_lookup_columns } ) {
        my %where;
        @where{@$colset} = $data->{@$colset};

        $rs->search( \%where )->count == 1 and
            return $rs->search( \%where )->first;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

{

    package App::Manoc::Form::CSVImport::RowImportInfo;

    use Moose;
    use namespace::autoclean;

    use Moose::Util::TypeConstraints;
    enum 'RowStatus', [qw(success error)];
    # avoid conflicts on message attribute
    no Moose::Util::TypeConstraints;

    has row_number => (
        is       => 'ro',
        isa      => 'Num',
        required => 1
    );

    has status => (
        is       => 'ro',
        isa      => 'RowStatus',
        required => 1
    );

    has message => (
        is  => 'rw',
        isa => 'Str',
    );

    __PACKAGE__->meta->make_immutable;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
