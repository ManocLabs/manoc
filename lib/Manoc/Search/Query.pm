# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Query;

use Moose;
use Moose::Util::TypeConstraints;

#use Smart::Comments;
use Carp;

use Manoc::Utils qw(str2seconds);
use Manoc::Search::QueryType;
use Manoc::Utils::IPAddress qw(padded_ipaddr check_partial_addr);

has 'search_string' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

enum 'QueryMatch' => [ qw(begin end exact partial) ];
has 'match'       => (
    is     => 'ro',
    isa    => 'QueryMatch',
    writer => '_match',
);

has 'query_type' => (
    is  => 'rw',
#    isa => 'QueryType',
);

# in seconds
has 'limit' => (
    is  => 'rw',
    isa => 'Int',
);

has 'words' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has 'subnet' => (
    is  => 'rw',
    isa => 'Str'
);

has 'prefix' => (
    is  => 'rw',
    isa => 'Int',
);

has 'sql_pattern' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_sql_pattern',
);

has 'start_date' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_start_date',
);

# shortcut for single word queries
# and magic guessing
sub query_as_word {
    return join( " ", @{ $_[0]->words } );
}

# Here we parse the user input in order to identify the scope of the query
# according to the mini-language keywords

sub parse {
    my $self = shift;

    my $text = $self->search_string();

    # use non capturing brackets
    my @TYPES = @Manoc::Search::QueryType::TYPES;
    scalar(Manoc::Search->_plugin_types) and 
      push @TYPES,  Manoc::Search->_plugin_types;

    my $types_re = '(?:' . join( '|', @TYPES ) . ')';

    #type's token (must be at the beginning of the line)
    if ( $text =~ /^($types_re)(\Z|\s)/gcos ) {
        $self->query_type( lc($1) );
    }

READ:
    {
        # explicit type's token
        if ( $text =~ /\Gtype(:|\s+)($types_re)(\Z|\s)/gcos ) {
            $self->query_type( lc($2) );
            redo READ;
        }

        # limit token
        if ( $text =~ /\Glimit(:|\s+)(\d+[smhdwMy])(\Z|\s)/gcos ) {
            $self->limit( str2seconds($2) );
            redo READ;
        }

        # ipcalc token
        if ( $text =~ /\G(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})(\Z|\s)/gcos ) {
            $self->query_type('subnet');
            $self->subnet($1);
            $self->prefix($2);
            redo READ;
        }

        # a word
        if ( $text =~ /\G([\w\.:-]+)(\Z|\s)/gcos ) {
            push @{ $self->words }, $1;
            redo READ;
        }

        # a quoted string
        if ( $text =~ /\G\"([^\"]+)\"(\Z|\s)/gcos ) {
            push @{ $self->words }, $1;
            $self->_match('exact');
            redo READ;
        }

        redo READ if $text =~ /\G\s+/gcos;
        redo READ if $text =~ /\G(.)/gcos;
    }

    #  automatic guessing only on single-word queries
    if ( @{ $self->words } == 1 ) {
        defined( $self->query_type ) or $self->_guess_query;

        defined( $self->query_type ) && !defined( $self->match ) and
            $self->_guess_match;

    }

    # set default query type
    $self->query_type or $self->query_type('inventory');

    # set default match type
    $self->match or $self->_match('partial');

    return 1;
}

# automatic match type guessing on ip and mac addresses
sub _guess_match {
    my $self = shift;

    my $type = $self->query_type;

    if ( $type eq 'ipaddr' || $type eq 'macaddr' || $type eq 'subnet' ) {
        my $text = $self->query_as_word;
        if ( ( $text =~ /^:.+:$/ ) || ( $text =~ /^\..+\.$/ ) || ( $text =~ /^-.+-$/ ) ) {
            $self->_match('partial');
        }
        elsif ( ( $text =~ /^[\.:-]/ ) ) {
            $self->_match('end');
        }
        elsif ( ( $text =~ /[\.:-]$/ ) ) {
            $self->_match('begin');
        }
        else {
            $self->_match('exact');
        }
    }
}

# Here we try to infer the search scope based on the query semantics
# (e.g. if the query include a :, we want to look up a mac address)
sub _guess_query {
    my $self = shift;

    scalar( @{ $self->words } ) == 1 or
        croak "cannot guess query when there is more than on word";

    my $text = lc( $self->query_as_word );
    ### Guessing query: $text

    if (
        ( !defined( $self->query_type ) || $self->query_type eq 'macaddr' ) &&
        $text =~ m{ ^(
		 ( ([0-9a-f]{2})? ([-:][0-9a-f]{2})+ [-:]? ) |
		 ([0-9a-f]{2}[-:])
		 )$
	     }xo
        )
    {
        $text =~ y/-/:/;
        $self->words( [$text] );
        $self->query_type('macaddr');
        return;
    }

    if (
        $text =~ m{
		    ^
		    ( ([0-9a-f]{4}) ?(\.[0-9a-f]{4})+ \.? ) |
		    ( [0-9a-f]{4}\. )
		    $
		}xo
        )
    {
        # cisco style mac
        $text = join( ':', map { unpack( '(a2)*', $_ ) } split( /\./, $text ) );
        $self->words( [$text] );
        $self->query_type('macaddr');
        return;
    }

    if ( check_partial_addr($text) ) {
      $self->query_type('ipaddr');
      return;
    }
}

sub _build_sql_pattern {
    my $self = shift;
    my $pattern = join( ' ', @{ $self->words } );
    return $pattern if ( !$pattern );
    
    if( check_partial_addr($pattern) ){
      $pattern = padded_ipaddr($pattern);
    }
    
    $self->match eq 'begin'   and $pattern = "$pattern%";
    $self->match eq 'end'     and $pattern = "%$pattern";
    $self->match eq 'partial' and $pattern = "%$pattern%";

    return $pattern;
}

sub _build_start_date {
    my $self = shift;
    my $now  = time;

    return $now - $self->limit;
}

no Moose;
__PACKAGE__->meta->make_immutable;
