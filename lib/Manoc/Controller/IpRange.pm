# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::IpRange;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Manoc::IpAddress;
use Manoc::Utils qw/netmask_prefix2range int2ip ip2int padded_ipaddr
    prefix2wildcard netmask2prefix
    check_addr /;
use POSIX qw/ceil/;
BEGIN { extends 'Catalyst::Controller'; }

# TODO: explain error->{field} vs error->{message}


=head1 NAME

Manoc::Controller::IpRange - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

#----------------------------------------------------------------------#

my $DEFAULT_PAGE_ITEMS = 64;
my $MAX_PAGE_ITEMS     = 1024;
my $DEF_TAB_POS        = 3;

#----------------------------------------------------------------------#

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect($c->uri_for_action('/iprange/list'));
}

=head2 base

=cut

sub base : Chained('/') : PathPart('iprange') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash( resultset => $c->model('ManocDB::IPRange') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('name') : CaptureArgs(1) {

    # $id = primary key
    my ( $self, $c, $id ) = @_;

    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !$c->stash->{object} ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=head2 range

=cut

sub range : Chained('base') : PathPart('range') : CaptureArgs(2) {
    my ( $self, $c, $host, $prefix ) = @_;

    unless ( $host or $prefix ) {
        $c->stash( error_msg => "Missing host or prefix parameter!" );
        $c->detach('/error/index');
    }
    my ( $from_i, $to_i, $network_i, $netmask ) = netmask_prefix2range( $host, $prefix );
    my $from = int2ip($from_i);
    my $to   = int2ip($to_i);

    my $range = $c->stash->{'resultset'}->search(
        {
            -and => [
                from_addr => Manoc::IpAddress->new( $from ),
                to_addr   => Manoc::IpAddress->new( $to ),
            ]
        }
    )->single;
    if ($range) {
        $c->stash( object => $range );
    }
    else {
        $c->stash( host => Manoc::IpAddress->new( $host ), prefix => $prefix );
    }
}

=head2 view_iprange

=cut

sub view_iprange : Chained('range') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $range = $c->stash->{'object'};

    if ($range) {
        $c->response->redirect( $c->uri_for_action( 'iprange/view', [ $range->name ] ) );
        $c->detach();
    }
    #N.B. in stash->{host} there is a Manoc::IpAddress object
    my $host   = $c->stash->{'host'}->address;
    my $prefix = $c->stash->{'prefix'};
    my ( $from_i, $to_i, $network_i, $netmask ) = netmask_prefix2range( $host, $prefix );
    $netmask = int2ip($netmask);
    my $from = int2ip($from_i);
    my $to   = int2ip($to_i);

    my %tmpl_param;
    $tmpl_param{host}     = $host;
    $tmpl_param{network}  = $from;
    $tmpl_param{netmask}  = $netmask;
    $tmpl_param{min_host} = int2ip( ip2int($from) + 1 );
    $tmpl_param{max_host} = $to;
    $tmpl_param{numhost}  = $to_i - $from_i - 1;
    $tmpl_param{wildcard} = prefix2wildcard($prefix);
    $tmpl_param{prefix}   = $prefix;
    $tmpl_param{template} = 'iprange/rangeview.tt';

    #prepare IpList parameters
    my $page = $c->req->param('page') || 1;
    my ( $prev_page, $next_page );
    $prev_page = $c->uri_for_action(
        'iprange/view_iprange',
        [ $host, $prefix ],
        { page => $page - 1, def_tab => $DEF_TAB_POS - 1 }
    );
    $next_page = $c->uri_for_action(
        'iprange/view_iprange',
        [ $host, $prefix ],
        { page => $page + 1, def_tab => $DEF_TAB_POS - 1 }
    );
    $c->stash( prev_page => $prev_page, next_page => $next_page );

    $c->stash(%tmpl_param);

    $self->ip_list( $c, $from, $to, $page );
}

=head2 ip_list

from xxx version $form and $to must be Manoc::IpAddress objects

=cut

sub ip_list : Private {
    my ( $self, $c, $from, $to, $page ) = @_;
    my $max_page_items = $c->req->param('items') || $DEFAULT_PAGE_ITEMS;

    # sanitize;
    $page < 0                         and $page           = 1;
    $max_page_items > $MAX_PAGE_ITEMS and $max_page_items = $MAX_PAGE_ITEMS;

    # paging arithmetics
    my $page_start_addr_i = ip2int($from);
    my $page_end_addr_i   = ip2int($to) + 1;
    my $page_size         = $page_end_addr_i - $page_start_addr_i;
    my $num_pages         = ceil( $page_size / $max_page_items );

    if ( $page > 1 ) {
        $page_start_addr_i += $max_page_items * ( $page - 1 );
        $page_size = $page_end_addr_i - $page_start_addr_i;
    }
    if ( $page_size > $max_page_items ) {
        $page_end_addr_i = $page_start_addr_i + $max_page_items;
        $page_size       = $max_page_items;
    }
    ( $page <= 1 )          and $c->stash( prev_page => undef );
    ( $page >= $num_pages ) and $c->stash( next_page => undef );

    # convert numeric address to normalized strings
    my $page_start_addr = Manoc::IpAddress->new(  int2ip($page_start_addr_i) );
    my $page_end_addr   = Manoc::IpAddress->new(  int2ip($page_end_addr_i) );

    my @rs;

    @rs = $c->model('ManocDB::Arp')->search(
        {
            -and => [
                ipaddr  => {'>=' => $page_start_addr},
		ipaddr  => {'<=' => $page_end_addr },
            ]
        },
	{
            select   => [ 'ipaddr', { 'max' => 'lastseen' } ],
            group_by => 'ipaddr',
            as => [ 'ipaddr', 'max_lastseen' ],
        }
    );
    my %arp_info =
        map { $_->ipaddr->address => print_timestamp( $_->get_column('max_lastseen') ) } @rs;

    @rs = $c->model('ManocDB::Ip')->search(
	 -and => [
            {'ipaddr'    => { '>=' => $page_start_addr }},
            {'ipaddr'    => { '<=' => $page_end_addr }},
	 ],
    );

    my %ip_info = map { $_->ipaddr->address => { assigned_to => $_->assigned_to,
						 desc        => $_->description,
						 notes       => $_->notes}
		      } @rs;

    my @addr_table;
    foreach my $i ( 0 .. $page_size - 1 ) {
        my $ipaddr = int2ip( $page_start_addr_i + $i );
        push @addr_table,
            {
            ipaddr      => $ipaddr,
            lastseen    => $arp_info{$ipaddr} || 'n/a',
            assigned_to => $ip_info{$ipaddr}->{assigned_to} || '',
	    desc        => $ip_info{$ipaddr}->{desc}   || '',
	    notes       => $ip_info{$ipaddr}->{notes}  || '',        
    };
    }
    $c->stash( addresses => \@addr_table );
     
    my $rs = $c->model('ManocDB::Arp')->search(
					       {
						-and => [
							 ipaddr  => {'>=' => Manoc::IpAddress->new($from) },
							 ipaddr  => {'<=' => Manoc::IpAddress->new($to)   },
							]
					       },
					       {
						select   => 'ipaddr',
						order_by => 'ipaddr',
						distinct => 1,
					       }
					      );
    
    #backref setting
    my $backref;
    if ( defined( $c->stash->{object} ) ) {
        $backref = $c->uri_for_action(
            'iprange/view',
            [ $c->stash->{object}->name ],
            { def_tab => '3', page => $page }
        );
    }
    else {
        $backref = $c->uri_for_action(
            '/iprange/view_iprange',
            [ $from, $c->stash->{prefix} ],
            { def_tab => '2', page => $page }
        );
    }

    
    $c->stash(
        ip_used            => $rs->count,
        disable_pagination => 1,
        disable_sorting    => 1,
        cur_page           => $page,
	    backref            => $backref,
    );
}

#----------------------------------------------------------------------#

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $iprange_rs = $c->stash->{'resultset'};
    my $range      = $c->stash->{'object'};

    $c->stash( default_backref => $c->uri_for_action('iprange/list') );

    if ( lc $c->req->method eq 'post' ) {
        if ( $iprange_rs->search( { parent => $range->name } )->count() ) {
            $c->flash(
                error_msg => $range->name . " cannot be deleted because has been splitted" );

            $c->stash(
                default_backref => $c->uri_for_action( 'iprange/view', [ $range->name ] ) );
            $c->detach('/follow_backref');
        }

        my $range = $iprange_rs->find( { name => $range->name } );
        my $parent = $range->parent;
        $parent and $parent = $parent->name;
        $range->delete();
        $c->flash( message => 'Success!! Ip range (' . $range->name . ') successful deleted.' );
        $c->detach('/follow_backref');
    }
    else {
        $c->stash( uri_form => $c->uri_for_action( 'iprange/delete', [ $range->name ] ) );
        $c->stash( template => 'generic_delete.tt' );
    }
}

#----------------------------------------------------------------------#

=head2 list

=cut

sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    my $schema = $c->stash->{resultset};

    my @subnet_list = $schema->search({},
				      {
				       order_by => ['me.from_addr','me.to_addr'],
				       #prefetch => ['vlan_id','children','parent'],
				       }
				     );
    
    $c->stash( subnet_list => \@subnet_list );
    $c->stash( template    => 'iprange/list.tt' );
}

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $range    = $c->stash->{'object'};
    my $name     = $range->name;
    my @children = map +{
        name       => $_->name,
        from_addr  => $_->from_addr->address,
        to_addr    => $_->to_addr->address,
        vlan_id    => $_->vlan_id ? $_->vlan_id->id : undef,
        vlan       => $_->vlan_id ? $_->vlan_id->name : "-",
        n_children => $_->children->count(),
	netmask    => $_->netmask,
        n_neigh    => get_neighbour(
				    $c->model('ManocDB::IPRange'), 
				    $name,
				    $_->from_addr,    
				    $_->to_addr
				   )->count(),
			},
        $range->search_related( 'children', undef, { order_by => 'from_addr' } );

    my $rs = $c->model('ManocDB::Arp')->search(
        {
            'ipaddr' => {
                '>=' => $range->from_addr,
                '<=' => $range->to_addr,
            }
        },
        {
            select   => 'ipaddr',
            order_by => 'ipaddr',
            distinct => 1,
        }
    );

    my $min_host = $range->from_addr;
    my $max_host = $range->to_addr;
    
    $range->netmask and $min_host = int2ip( ip2int( $range->from_addr ) + 1 ) and 
      $max_host = int2ip( ip2int( $range->to_addr ) - 1 );

    my %param;
    $param{prefix}     = $range->netmask ? netmask2prefix( $range->netmask->address ) : '';
    $param{wildcard}   = prefix2wildcard( $param{prefix} );
    $param{min_host}   = int2ip( ip2int( $range->from_addr->address ) + 1 );
    $param{max_host}   = int2ip( ip2int( $range->to_addr->address ) - 1 );
    $param{numhost}    = ip2int( $param{max_host} ) - ip2int( $param{min_host} ) - 1;
    $param{ipaddr_num} = $rs->count();

    $c->stash( childrens => \@children );
    $c->stash(%param);

    #prepare IpList parameters
    my $page = $c->req->param('page') || 1;
    my ( $prev_page, $next_page );
    $prev_page = $c->uri_for_action(
        'iprange/view',
        [ $range->name ],
        { page => $page - 1, def_tab => $DEF_TAB_POS }
    );
    $next_page = $c->uri_for_action(
        'iprange/view',
        [ $range->name ],
        { page => $page + 1, def_tab => $DEF_TAB_POS }
    );
    $c->stash( prev_page => $prev_page, next_page => $next_page );

    $self->ip_list( $c, $range->from_addr->address, $range->to_addr->address, $page );
    $c->stash( template => 'iprange/view.tt' );
}

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $name      = $c->req->param('name');
    my $new_name  = $c->req->param('new_name');
    my $from_addr = $c->req->param('from_addr');
    my $to_addr   = $c->req->param('to_addr');
    my $network   = $c->req->param('network');
    my $type      = $c->req->param('type');
    my $vlan_id   = $c->req->param('vlan');
    my $prefix    = $c->req->param('prefix');
    my $netmask;

    $c->stash(
        default_backref => $c->uri_for_action( '/iprange/view', [ $c->stash->{object}->name ] )
    );

    my ( $message, $error );
    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }

        my $done = $c->forward('process_edit');
        if ($done) {
            $c->flash( message => 'Success! Ip Range edited' );
            $c->stash( default_backref => $c->uri_for_action( "iprange/view", [$new_name] ) );
            $c->detach('/follow_backref');
        }
    }

    my %tmpl_param;
    my $range = $c->stash->{'object'};

    $name = $range->name;
    $new_name ||= $name;

    $from_addr ||= $range->from_addr;
    $to_addr   ||= $range->to_addr;
    $network   ||= $range->network;
    $netmask = $range->netmask;
    $vlan_id = $range->vlan_id ? $range->vlan_id->id : '';

    if ( !$type && $network && $netmask) {
        $type   = 'subnet';
	$c->log->info("netmask = '$netmask");
        $prefix = Manoc::Utils::netmask2prefix($netmask->address);
    }
    
    if ( !defined($prefix) ) {
        $type = 'range';
        $network = $netmask = undef;
    }

    my @vlans_rs = $c->model('ManocDB::Vlan')->search();
    my @vlans = map { id => $_->id, name => $_->name, selected => $_->id eq $vlan_id, },
        @vlans_rs;

    $tmpl_param{range_name}  = $name;
    $tmpl_param{new_name}    = $new_name;
    $tmpl_param{error_msg}   = $c->stash->{message};
    $tmpl_param{type_subnet} = $type eq 'subnet';
    $tmpl_param{type_range}  = $type eq 'range';
    $tmpl_param{vlans}       = \@vlans;
    $tmpl_param{from_addr}   = $from_addr;
    $tmpl_param{to_addr}     = $to_addr;
    $tmpl_param{network}     = $network;
    $tmpl_param{prefixes} =
        [ map { id => $_, label => $_, selected => $prefix && $prefix == $_, }, ( 0 .. 32 ) ];

    $tmpl_param{template} = 'iprange/edit.tt';
    $c->stash(%tmpl_param);
}

sub process_edit : Private {
    my ( $self, $c ) = @_;

    my $name     = $c->req->param('name');
    my $new_name = $c->req->param('new_name');
    my $vlan_id  = $c->req->param('vlan');
    my $desc     = $c->req->param('description');
    my $type     = $c->req->param('type');
    my $error    = {};

    my $range = $c->stash->{'object'};

    $vlan_id eq "none" and undef $vlan_id;

    # check name parameter
    if ( lc($name) ne lc($new_name) && !$c->forward('check_name', [ $new_name ]) ) {
	$c->stash->{error}->{name} = $c->stash->{message}; 
	$c->stash->{message} = undef; 
	return 0;
    }

    # check parameters and store cleaned values in stash
    $c->forward('check_iprange_form') or return 0;
        
    #Update range    
    $range->set_column( 'name',        $new_name );
    $range->set_column( 'from_addr',   $c->stash->{from_addr});
    $range->set_column( 'to_addr',     $c->stash->{to_addr});
    $range->set_column( 'network',     $c->stash->{network});
    $range->set_column( 'netmask',     $c->stash->{netmask});
    $range->set_column( 'vlan_id',     $vlan_id );
    $range->set_column( 'description', $desc || '');
    $range->update or return 0;

    return 1;
}

#----------------------------------------------------------------------#

sub create : Chained('base') : PathPart('create') : Args() {
    my ( $self, $c, $parent ) = @_;

    my $vlan_id = $c->req->param('vlan') || '';
    $c->stash( default_backref => $c->uri_for_action('/iprange/list') );

    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }
        my $done = $c->forward('process_create');
        if ($done) {
            $c->flash( message => $c->stash->{message} );

            $c->stash( default_backref =>
                    $c->uri_for_action( "iprange/view", [ $c->req->param('name') ] ) );
            $c->detach('/follow_backref');
        }
    }

    my $type   = $c->req->param('type');
    my $prefix = $c->req->param('prefix');
    my %tmpl_param;

    $tmpl_param{prefixes} =
        [ map { id => $_, label => $_, selected => $prefix && $prefix == $_, }, ( 0 .. 32 ) ];

    if ($parent) {
        my $par_obj = $c->stash->{'resultset'}->find($parent);
        $tmpl_param{p_from} =
            $par_obj->network
          ? $par_obj->network->address
          : $par_obj->from_addr->address;
        $tmpl_param{p_prefix} =
          $par_obj->netmask ? netmask2prefix( $par_obj->netmask ) : undef;
        $tmpl_param{p_to} = $par_obj->to_addr->address;
    }


    my @vlans_rs = $c->model('ManocDB::Vlan')->search();
    my @vlans = map { id => $_->id, name => $_->name, selected => $_->id eq $vlan_id },
        @vlans_rs;


    foreach (qw( network prefix from_addr to_addr )) {
        $tmpl_param{$_} = $c->req->param($_);
    }
    $tmpl_param{range}       = $c->req->param('name');
    $tmpl_param{parent}      = $parent;
    $tmpl_param{type_subnet} = defined($type) && $type eq 'subnet';
    $tmpl_param{type_range}  = defined($type) && $type eq 'range';
    $tmpl_param{vlans}       = \@vlans;

    $tmpl_param{template} = 'iprange/create.tt';

    $c->stash(%tmpl_param);
}

sub process_create : Private {
    my ( $self, $c ) = @_;
    my $name    = $c->req->param('name');
    my $vlan_id = $c->req->param('vlan');
    my $desc    = $c->req->param('description');
    my $error;

    $vlan_id eq "none" and undef $vlan_id;

    # check name parameter
    if ( $name ) {
	$c->forward('check_name', [ $name ]) or 
	  $c->stash->{error}->{name} = $c->stash->{message}; 
    } else {
	$c->stash->{error}->{name} = "Missing field";
    }
    scalar( keys(%{$c->stash->{error}}) ) and return 0;

    # check form
    $c->forward('check_iprange_form') || return 0; 

    my $ret = $c->stash->{'resultset'}->create({
						name      => $name,
						parent    => $c->stash->{parent_name},
						from_addr => $c->stash->{from_addr},
						to_addr   => $c->stash->{to_addr},
						network   => $c->stash->{network},
						netmask   => $c->stash->{netmask},
						vlan_id   => $vlan_id,
					       });
    if (! $ret ) {
	$c->stash->{message} = "Cannot create requested iprange";
	return 0;
    } else {
	$c->stash->{message} = "Created '$name'";
	return 1;
    }
}

sub split : Chained('object') : PathPart('split') : Args(0) {
    my ( $self, $c ) = @_;
    my ( $done, $message, $error );
    my %tmpl_param;
    my $parent           = $c->req->param('parent');
    my $name             = $c->req->param('name');
    my $name1            = $c->req->param('name1');
    my $name2            = $c->req->param('name2');
    my $split_point_addr = $c->req->param('split_point_addr');

    $c->stash(
        default_backref => $c->uri_for_action( '/iprange/view', [ $c->stash->{object}->name ] )
    );

    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }

        ( $done, $message, $error ) = $self->process_split($c);
        if ($done) {
            $c->flash( message => "Success!! $message" );
            $c->stash( default_backref => $c->uri_for_action('iprange/list') );
            $c->detach('/follow_backref');
        }
    }

    my $range     = $c->stash->{'object'};
    my $from_addr_str = $range->from_addr->address ;
    my $to_addr_str   = $range->to_addr->address;
    $parent = $range->parent;
    $parent and $parent = $parent->name;

    $tmpl_param{error}            = $error;
    $tmpl_param{error_msg}        = $message;
    $tmpl_param{range_name}       = $range->name;
    $tmpl_param{parent}           = $parent;
    $tmpl_param{from_addr}        = $from_addr_str;
    $tmpl_param{to_addr}          = $to_addr_str;
    $tmpl_param{name1}            = $name1;
    $tmpl_param{name2}            = $name2;
    $tmpl_param{split_point_addr} = $split_point_addr;
    $tmpl_param{template}         = 'iprange/split.tt';

    $c->stash(%tmpl_param);
}

sub process_split : Private {
    my ( $self, $c ) = @_;
    my $error = {};

    #Get parameters
    my $name             = $c->req->param('name');
    my $name1            = $c->req->param('name1');
    my $name2            = $c->req->param('name2');
    my $split_point_addr = $c->req->param('split_point_addr');

    my $range = $c->stash->{'object'};


    #Retrieve subnet info
    my $from_addr = $range->from_addr;
    my $to_addr   = $range->to_addr;
    my $parent    = $range->parent;
    my $vlan_id   = $range->vlan_id;

    #Check parameters

    if ($name1) {
	$c->forward('check_name', [ $name1 ]) or
	  $error->{name1} = $c->stash->{message};
    } else {
	$error->{name1} = "Missing field";
    }
    
    if ($name2) {
	$c->forward('check_name', [ $name2 ]) or
	  $error->{name2} = $c->stash->{message};
    } else {
	$error->{name2} = "Missing field";
    }

  
    if ( $name1 and $name1 eq $name2 ) {
        $error->{name2} = "Name Subnet 1 and Name Subnet 2 cannot be the same";
    }

    #Check split point address
    if ($split_point_addr) {
	if ( check_addr($split_point_addr) ) {

	    $split_point_addr = Manoc::IpAddress->new($split_point_addr);
	    
	    if ( ( $from_addr gt $split_point_addr ) ||
		 ( $to_addr le $split_point_addr ) )
	      {
		  $error->{split} = "Split point address not inside the range";
	      }
	} else {
	    $error->{split} = "Not a valid IPv4 address";
	}	
    } else {
	$error->{split} = "Missing field";
    }

    if ( $range->children->count() ) {

        # should also be checked in rangelist.tmpl
        $error->{split} = "$name cannot be splitted because it is divided in subranges";
    }
    scalar( keys(%$error) ) and return ( 0, undef, $error );

    #Update DB
    my $rs = $c->stash->{'resultset'};
    $c->model('ManocDB')->txn_do(
        sub {
            $range->delete;
	    $rs->create(
                {
                    name      => $name1,
                    parent    => $parent,
                    from_addr => $from_addr,
                    to_addr   => $split_point_addr,
                    netmask   => undef,
                    network   => undef,
                    vlan_id   => $vlan_id,
                }
                ) or
                return ( 0, "Impossible split range" );

	    my $split_next_addr = ip2int($split_point_addr->address) + 1;

            $rs->create(
                {
                    name      => $name2,
                    parent    => $parent,
                    from_addr => Manoc::IpAddress->new( int2ip($split_next_addr) ),
                    to_addr   => $to_addr,
                    netmask   => undef,
                    network   => undef,
                    vlan_id   => $vlan_id
                }
                ) or
                return ( 0, "Impossible split range" );
        }
    );

    if ($@) {
        my $commit_error = $@;
        return ( 0, "Error while updating database: $commit_error" );
    }

    return ( 1, "Range splitted succesfully" );
}

sub merge : Chained('object') : PathPart('merge') : Args(0) {
    my ( $self, $c ) = @_;
    my ( $done, $message, $error );
    my %tmpl_param;
    my $parent   = $c->req->param('parent');
    my $name     = $c->req->param('name');
    my $new_name = $c->req->param('new_name');
    my $neigh    = $c->req->param('neigh');
    my $obj      = $c->stash->{'object'};

    $c->stash(
        default_backref => $c->uri_for_action( '/iprange/view', [ $c->stash->{object}->name ] )
    );

    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }
        ( $done, $message, $error ) = $self->process_merge($c);
        if ($done ) {
            $c->flash( message => "Success!! $message" );
            $c->detach('/follow_backref');

        }
    }

    my $range     = $c->stash->{'object'};
    my $from_addr = $range->from_addr;
    my $to_addr   = $range->to_addr;

    $parent = $range->parent;
    if ($parent) { $parent = $parent->name; }

    my @neighbours = map {
        name        => $_->name,
            from    => $_->from_addr->address,
            to      => $_->to_addr->address,
            checked => ( $neigh eq ( $_->name ) ),
    }, get_neighbour( $c->stash->{'resultset'}, $parent, $from_addr, $to_addr );

    $tmpl_param{error}      = $error;
    $tmpl_param{error_msg}  = $message;
    $tmpl_param{range_name} = $range->name;
    $tmpl_param{from_addr}  = $from_addr->address;
    $tmpl_param{to_addr}    = $to_addr->address;
    $tmpl_param{parent}     = $parent;
    $tmpl_param{neighbours} = \@neighbours;
    $tmpl_param{new_name}   = $new_name;
    $tmpl_param{neigh}      = $neigh;
    $tmpl_param{template}   = 'iprange/merge.tt';

    $c->stash(%tmpl_param);
}

sub process_merge : Private {
    my ( $self, $c ) = @_;

    #Get parameters
    my $name     = $c->req->param('name');
    my $neigh    = $c->req->param('neigh');
    my $new_name = $c->req->param('new_name');
    my $error    = {};

    #Check parameters
    unless ( $neigh ) {
	$c->stash->{message} = "Please select the neighbour range";
	return 0;
    }

    $c->forward('check_name', [ $new_name ]) or
      $error->{name} = $c->stash->{error};

    scalar( keys(%$error) ) and return ( 0, undef, $error );

    #Retrieve subnet info
    my $rs        = $c->stash->{'resultset'}->find($name);
    my $from_addr = $rs->from_addr ;
    my $to_addr   = $rs->to_addr ;
    my $parent    = $rs->parent;
    my $vlan_id   = $rs->vlan_id;

    #Retrieve neigh subnet info

    $rs = $c->stash->{'resultset'}->find($neigh);
    my $neigh_from_addr =  $rs->from_addr;
    my $neigh_to_addr   =  $rs->to_addr;

    if ($parent) {

        #Retrieve parent subnet info
        my $rs               = $c->stash->{'resultset'}->find( $parent->name );
        my $parent_from_addr = $rs->from_addr;
        my $parent_to_addr   = $rs->to_addr;

        #Check if the merged subnet and the parent subnet has the same range
        if (
            ( ( $from_addr eq $parent_from_addr ) && ( $neigh_to_addr eq $parent_to_addr ) ) ||
            ( ( $neigh_from_addr eq $parent_from_addr ) &&
                ( $to_addr eq $parent_to_addr ) )
            )
        {
            return ( 0, "Merged and parent subnets has the same range!" );
        }
    }

    #Check subnets' children
    if ( $c->stash->{'resultset'}->search( parent => $name )->count() ) {
        return ( 0, "$name cannot be merged because it is divided in subranges" );
    }
    if ( $c->stash->{'resultset'}->search( parent => $neigh )->count() ) {
        return ( 0, "$name cannot be merged because $neigh it is divided in subranges" );
    }

    #Update DB
    $c->model('ManocDB')->txn_do(
        sub {
            $c->stash->{'resultset'}->search( { name => "$name" } )->delete;
            $c->stash->{'resultset'}->search( { name => "$neigh" } )->delete;
            $c->stash->{'resultset'}->create(
                {
                    name      => $new_name,
                    parent    => $parent,
                    from_addr => (
                        $from_addr lt $neigh_from_addr ? $from_addr :
                            $neigh_from_addr
                    ),
                    to_addr => (
                        $to_addr gt $neigh_to_addr ? $to_addr :
                            $neigh_to_addr
                    ),
                    netmask => undef,
                    network => undef,
                    vlan_id => $vlan_id
                }
            );
        }
    );

    if ($@) {
        my $commit_error = $@;
        return ( 0, "Impossible update database: $commit_error" );
    }

    return ( 1, "Range merged succesfully" );
}

#-----------------------------------------------------------------#
# check for valid name and if a schema is given against duplicates
# names

sub check_name : Private {
    my ( $self, $c, $name) = @_;
    my $schema = $c->stash->{resultset};

    if ( $name eq '' ) {
	$c->stash->{message} = "Empty name";
	return 0;
    }
    if ( $name !~ /^\w[\w-]*$/ ) {
	$c->stash->{message} = "Invalid name";
	return 0;
    }

    if ($schema->search({ name => $name})->count() > 0 ) {
	$c->stash->{message} = "Duplicated name";
	$c->log->error("duplicated $name");
	return 0;
    }

    return 1;
}


# TODO: rewrite all return to use stash error and message
sub check_iprange_form : Private {
    my ( $self, $c ) = @_;

    my $name      = $c->req->param('name');
    my $type      = $c->req->param('type');
    my $vlan_id   = $c->req->param('vlan');
    my $from_addr_str = $c->req->param('from_addr'); #unpadded string
    my $to_addr_str   = $c->req->param('to_addr');   #unpadded string
    my $network_str   = $c->req->param('network');   #unpadded string
    my $netmask;

    my $range = $c->stash->{'object'};

    # init error hash and store a reference in stash
    my $error;
    if ( $c->stash->{error}) {
	$error = $c->stash->{error};
    } else {
	$error = $c->stash->{error} = {};
    }
    #prepare padded object in order to compare them later
    my $network;
    my $from_addr;
    my $to_addr;

    if ( $type eq 'subnet' ) {
        
        $network_str or $error->{type} = "Please insert range network";
        check_addr($network_str) or $error->{type} = "Invalid network address";

	$network   = Manoc::IpAddress->new($network_str);

        my $prefix  = $c->req->param('prefix');
        $prefix or $error->{prefix} = "Please insert network prefix";
        $prefix =~ /^\d+$/ and
            ( $prefix >= 0 || $prefix <= 32 ) or
            $error->{type} = "Invalid network prefix";

        scalar( keys(%$error) ) and return 0;

        my ( $from_addr_i, $to_addr_i, $network_i, $netmask_i ) =
            Manoc::Utils::netmask_prefix2range( $network_str, $prefix );

        if ( $network_i != $from_addr_i ) {
            $error->{type} = "Bad network. Do you mean " . int2ip($from_addr_i) . "?";
	  }

	$to_addr   = Manoc::IpAddress->new(int2ip($to_addr_i));
	$from_addr = Manoc::IpAddress->new(int2ip($from_addr_i));
	$netmask   = Manoc::IpAddress->new(int2ip($netmask_i));
    } elsif ( $type eq 'range' ) {
      if( !check_addr($from_addr_str) ){ 
	$error->{from_addr} = "Not a valid IPv4 address";
	return 0;
      } 
      if( !check_addr($to_addr_str) ){ 
	$error->{to_addr} = "Not a valid IPv4 address";
	return 0;
      }
      $to_addr   = Manoc::IpAddress->new($to_addr_str);
      $from_addr = Manoc::IpAddress->new($from_addr_str);

      if($to_addr le $from_addr) {                
	$error->{from_addr} = "Bad range!";
	return 0; 
      }
      $network = $netmask = undef;
    } else {
	# internal error?
	$c->stash->{'message'} = "No type selected";
	return 0;
    }
    scalar( keys(%$error) ) and return 0;

   
    # WARNING: now to_addr and from_addr MUST be zero padded!

    # check parent parameter and overlappings
    my $parent;
    if ($range) {
	# we are editing a range
	$parent = $range->parent;
    } else {
	# we are creating a range
	my $parent_name = $c->req->param('parent') || undef;
	if ($parent_name) {
	    $parent = $c->stash->{'resultset'}->find($parent_name);
	    if (!$parent) {
		$c->stash->{message} = "Invalid parent name '$parent_name'";
		return 0;
	    }
	}
	$c->stash->{parent_name} = $parent_name;
    }
    if ($parent) {
        # range should be inside its parent
	if ( ($from_addr lt $parent->from_addr) || ($to_addr gt $parent->to_addr) )
	  {
	      $c->stash->{error_msg} = 
		"Invalid range: overlaps with its parent (" . $parent->from_addr->address . " - " .
		  $parent->to_addr->address . ")";
	      return 0;
	  }

        #Check if the range is the same of the father
	if ( $from_addr eq $parent->from_addr && $to_addr eq $parent->to_addr ) 
	  {
	      $c->stash->{error_msg} = "Invalid range: can't be the same as the parent range" ;
	      return 0;
	  }

    }

    # a range cannot overlap any sibling range
    my $conditions = [
		      {
		       'from_addr' => { '<=' => $from_addr },
		       'to_addr'   => { '>=' => $from_addr },
		      },
		      {
		       'from_addr' => { '<=' => $to_addr },
		       'to_addr'   => { '>=' => $to_addr },
		      },
		      {
		       'from_addr' => { '>=' => $from_addr },
		       'to_addr'   => { '<=' => $to_addr },
		      }
		     ];
    if ( defined($parent) ) {
	foreach my $condition (@$conditions) {
	    $condition->{parent} = $parent->name;
	}
    }
    else {
	foreach my $condition (@$conditions) {
	    $condition->{parent} = undef;
	}
    }
    if ( defined($range) ) {
	# avoid compare the range with itself!
	foreach my $condition (@$conditions) {
	    $condition->{name} = { '!=' => $name };
	}
    }
    my @rows = $c->stash->{'resultset'}->search($conditions);
    if ( @rows ) {
	 $c->stash->{error_msg} = 
	   "Invalid range: overlaps with " . $rows[0]->name . " (" . $rows[0]->from_addr->address . " - " .
	     $rows[0]->to_addr->address . ")";
	 return 0;
     }


    # when editing a range check that it cannot overlap any descendant range
    # and must have every children inside the range
    if ( $range ) {
	$conditions = [
		       {
			'from_addr' => { '<' => $from_addr },
			'to_addr'   => { '>' => $from_addr },
			'parent'    => { '=' => $name }
		       },
		       {
			'from_addr' => { '<' => $to_addr },
			'to_addr'   => { '>' => $to_addr },
			'parent'    => { '=' => $name }
		       },
		       {
			'to_addr' => { '<' => $from_addr },
			'parent'  => { '=' => $name }
		       },
		       {
			'from_addr' => { '>' => $to_addr },
			'parent'     => { '=' => $name }
		       },
		      ];
	@rows = $c->stash->{'resultset'}->search($conditions);
	if ( @rows > 0 ) {
	    $c->stash->{error_msg} = "Invalid range (conflicts " . $rows[0]->name . ")" ;
	    return 0;
	}
    }

    scalar( keys(%$error) ) and return 0;
    
    # put in stash ip address objects
    $c->stash->{'from_addr'} = $from_addr || die;
    $c->stash->{'to_addr'}   = $to_addr   || die;
    $c->stash->{'network'}   = $network   || die;
    $c->stash->{'netmask'}   = $netmask   || die;

    return 1;
}


sub get_neighbour {
    my ( $schema, $parent, $from_addr, $to_addr ) = @_;
    
    my $lower_addr = int2ip(ip2int($from_addr->address) - 1);
    my $upper_addr = int2ip(ip2int($to_addr->address) + 1);

    $schema->search(
        {
            parent => $parent,
            -or    => [
                { 'to_addr'   => Manoc::IpAddress->new($lower_addr) },
                { 'from_addr' => Manoc::IpAddress->new($upper_addr) },
            ]
        }
    );
}

=head1 AUTHOR

The MANOC Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
