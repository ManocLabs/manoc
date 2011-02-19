# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::IpRange;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Manoc::Utils qw/netmask_prefix2range int2ip ip2int
    print_timestamp prefix2wildcard netmask2prefix
    check_addr /;
use POSIX qw/ceil/;
BEGIN { extends 'Catalyst::Controller'; }

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

    $c->response->redirect('/iprange/list');
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
                from_addr => $from,
                to_addr   => $to,
            ]
        }
    )->single;
    if ($range) {
        $c->stash( object => $range );
    }
    else {
        $c->stash( host => $host, prefix => $prefix );
    }
}

=head2 view_iprange

=cut

sub view_iprange : Chained('range') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $range = $c->stash->{'object'};

    if ($range) {
        $c->response->redirect( $c->uri_for_action( 'iprange/view', [ $range->name ] ) )
            if ($range);
        $c->detach();
    }
    my $host   = $c->stash->{'host'};
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

    $self->ip_list( $c, $from_i, $to_i, $page );
    $c->stash(%tmpl_param);
}

=head2 ip_list

=cut

sub ip_list : Private {
    my ( $self, $c, $from_i, $to_i, $page ) = @_;
    my $max_page_items = $c->req->param('items') || $DEFAULT_PAGE_ITEMS;

    # sanitize;
    $page < 0                         and $page           = 1;
    $max_page_items > $MAX_PAGE_ITEMS and $max_page_items = $MAX_PAGE_ITEMS;

    # paging arithmetics
    my $page_start_addr = $from_i;
    my $page_end_addr   = $to_i;
    my $page_size       = $page_end_addr - $page_start_addr;
    my $num_pages       = ceil( $page_size / $max_page_items );
    if ( $page > 1 ) {
        $page_start_addr += $max_page_items * ( $page - 1 );
        $page_size = $page_end_addr - $page_start_addr;
    }
    if ( $page_size > $max_page_items ) {
        $page_end_addr = $page_start_addr + $max_page_items;
        $page_size     = $max_page_items;
    }
    ( $page <= 1 )          and $c->stash( prev_page => undef );
    ( $page >= $num_pages ) and $c->stash( next_page => undef );

    my @rs;
    @rs = $c->model('ManocDB::Arp')->search(
        {
            'inet_aton(ipaddr)' => {
                '>=' => $page_start_addr,
                '<=' => $page_end_addr,
            }
        },
        {
            select   => [ 'ipaddr', { 'max' => 'lastseen' } ],
            group_by => 'ipaddr',
            as => [ 'ipaddr', 'max_lastseen' ],
        }
    );
    my %arp_info =
        map { $_->ipaddr => print_timestamp( $_->get_column('max_lastseen') ) } @rs;

    @rs = $c->model('ManocDB::IpNotes')->search(
        {
            'inet_aton(ipaddr)' => {
                '>=' => $page_start_addr,
                '<=' => $page_end_addr,
            }
        }
    );
    my %ip_note = map { $_->ipaddr => $_->notes } @rs;

    my @addr_table;
    foreach my $i ( 0 .. $page_size - 1 ) {
        my $ipaddr = int2ip( $page_start_addr + $i );
        push @addr_table,
            {
            ipaddr   => $ipaddr,
            lastseen => $arp_info{$ipaddr} || 'n/a',
            notes    => $ip_note{$ipaddr} || '',
            };
    }
    $c->stash( addresses => \@addr_table );

    my $rs = $c->model('ManocDB::Arp')->search(
        {
            'inet_aton(ipaddr)' => {
                '>=' => $from_i,
                '<=' => $to_i,
            }
        },
        {
            select   => 'ipaddr',
            order_by => 'ipaddr',
            distinct => 1,
        }
    );

    $c->stash(
        ip_used            => $rs->count,
        disable_pagination => 1,
        disable_sorting    => 1,
        cur_page           => $page
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

    my @subnet_list = $schema->all();

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
        from_addr  => $_->from_addr,
        to_addr    => $_->to_addr,
        vlan_id    => $_->vlan_id ? $_->vlan_id->id : undef,
        vlan       => $_->vlan_id ? $_->vlan_id->name : "-",
        n_children => $_->children->count(),
        n_neigh    => get_neighbour(
            $c->model('ManocDB::IPRange'), $name,
            ip2int( $_->from_addr ),       ip2int( $_->to_addr )
            )->count(),
        },
        $range->search_related( 'children', undef, { order_by => 'inet_aton(from_addr)' } );

    my $rs = $c->model('ManocDB::Arp')->search(
        {
            'inet_aton(ipaddr)' => {
                '>=' => ip2int( $range->from_addr ),
                '<=' => ip2int( $range->to_addr ),
            }
        },
        {
            select   => 'ipaddr',
            order_by => 'ipaddr',
            distinct => 1,
        }
    );
    my %param;
    $param{prefix}     = $range->netmask ? netmask2prefix( $range->netmask ) : '';
    $param{wildcard}   = prefix2wildcard( $param{prefix} );
    $param{min_host}   = int2ip( ip2int( $range->from_addr ) + 1 );
    $param{max_host}   = int2ip( ip2int( $range->to_addr ) - 1 );
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

    $self->ip_list( $c, ip2int( $range->from_addr ), ip2int( $range->to_addr ), $page );
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

        my $done;
        ( $done, $message, $error ) = $self->process_edit($c);
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

    if ( !$type && defined($network) && defined($netmask) ) {
        $type   = 'subnet';
        $prefix = Manoc::Utils::netmask2prefix($netmask);
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
    $tmpl_param{error}       = $error;
    $tmpl_param{error_msg}   = $message;
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

sub process_edit {
    my ( $self, $c ) = @_;

    my $name     = $c->req->param('name');
    my $new_name = $c->req->param('new_name');
    my $vlan_id  = $c->req->param('vlan');
    my $desc     = $c->req->param('description');
    my $type     = $c->req->param('type');
    my $error    = {};

    my ( $from_addr_i, $to_addr_i, $network_i, $netmask_i );

    my ( $res, $mess );

    my $range = $c->stash->{'object'};

    $vlan_id eq "none" and undef $vlan_id;

    # check name parameter
    if ( lc($name) ne lc($new_name) ) {
        ( $res, $mess ) = check_name( $new_name, $c->stash->{'resultset'} );
        $res or $error->{name} = $mess;
    }

    if ( $type eq 'subnet' ) {
        my $network = $c->req->param('network');
        my $prefix  = $c->req->param('prefix');

        $network             or $error->{type} = "Missing network";
        $prefix              or $error->{type} = "Missing prefix";
        check_addr($network) or $error->{type} = "Bad network address";

        $prefix =~ /^\d+$/ and
            ( $prefix >= 0 || $prefix <= 32 ) or
            $error->{type} = "Bad subnet prefix";

        scalar( keys(%$error) ) and return ( 0, undef, $error );

        ( $from_addr_i, $to_addr_i, $network_i, $netmask_i ) =
            Manoc::Utils::netmask_prefix2range( $network, $prefix );

        if ( $network_i != $from_addr_i ) {
            $error->{type} = "Bad network. Do you mean " . int2ip($from_addr_i) . "?";
        }
    }
    elsif ( $type eq 'range' ) {
        my $from_addr = $c->req->param('from_addr');
        my $to_addr   = $c->req->param('to_addr');

        defined($from_addr) or
            $error->{type} = "Please insert range from address";
        check_addr($from_addr) or
            $error->{type} = "Start address not a valid IPv4 address";

        defined($to_addr) or
            $error->{type} = "Please insert range to address";
        check_addr($to_addr) or
            $error->{type} = "End address not a valid IPv4 address";

        $network_i = undef;
        $netmask_i = undef;

        $to_addr_i   = ip2int($to_addr);
        $from_addr_i = ip2int($from_addr);
        $error->{type} = "Invalid range" unless ( $to_addr_i >= $from_addr_i );

    }
    else {
        return ( 0, "Unexpected form parameter (type)" );
    }
    scalar( keys(%$error) ) and return ( 0, undef, $error );

    # check parent parameter and overlappings
    my $parent = $range->parent;
    if ($parent) {

        # range should be inside its parent
        unless ( $from_addr_i >= ip2int( $parent->from_addr ) &&
            $to_addr_i <= ip2int( $parent->to_addr ) )
        {
            return ( 0,
                "Invalid range: overlaps with its parent (" . $parent->from_addr . " - " .
                    $parent->to_addr . ")" );
        }

        #Check if the range is the same of the father
        ( ( $from_addr_i == ip2int( $parent->from_addr ) ) &&
                ( $to_addr_i == ip2int( $parent->to_addr ) ) ) and
            return ( 0, "Invalid range: can't be the same as the parent range" );

    }

    #cannot overlap any sibling range
    my $conditions = [
        {
            'inet_aton(from_addr)' => { '<=' => $from_addr_i },
            'inet_aton(to_addr)'   => { '>=' => $from_addr_i },
            name                   => { '!=' => $name }
        },
        {
            'inet_aton(from_addr)' => { '<=' => $to_addr_i },
            'inet_aton(to_addr)'   => { '>=' => $to_addr_i },
            name                   => { '!=' => $name }
        },
        {
            'inet_aton(from_addr)' => { '>=' => $from_addr_i },
            'inet_aton(to_addr)'   => { '<=' => $to_addr_i },
            name                   => { '!=' => $name }
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
    my @rows = $c->stash->{'resultset'}->search($conditions);
    @rows and
        return ( 0,
        "Invalid range: overlaps with " . $rows[0]->name . " (" . $rows[0]->from_addr . " - " .
            $rows[0]->to_addr . ")" );

    #cannot overlap any son range and must have them inside the range
    $conditions = [
        {
            'inet_aton(from_addr)' => { '<' => $from_addr_i },
            'inet_aton(to_addr)'   => { '>' => $from_addr_i },
            parent                 => { '=' => $name }
        },
        {
            'inet_aton(from_addr)' => { '<' => $to_addr_i },
            'inet_aton(to_addr)'   => { '>' => $to_addr_i },
            parent                 => { '=' => $name }
        },
        {
            'inet_aton(to_addr)' => { '<' => $from_addr_i },
            parent               => { '=' => $name }
        },
        {
            'inet_aton(from_addr)' => { '>' => $to_addr_i },
            parent                 => { '=' => $name }
        },
    ];
    @rows = $c->stash->{'resultset'}->search($conditions);
    @rows and
        return ( 0, "Invalid range (conflicts " . $rows[0]->name . ")" );

    #Update range
    $range->set_column( 'name',        $new_name );
    $range->set_column( 'from_addr',   int2ip($from_addr_i) );
    $range->set_column( 'to_addr',     int2ip($to_addr_i) );
    $range->set_column( 'network',     $network_i ? int2ip($network_i) : undef );
    $range->set_column( 'netmask',     $netmask_i ? int2ip($netmask_i) : undef );
    $range->set_column( 'vlan_id',     $vlan_id );
    $range->set_column( 'description', $desc );
    $range->update or
        return ( 0, "Cannot update range" );

    return ( 1, "updated '$name' (" . int2ip($from_addr_i) . "-" . int2ip($to_addr_i) . ")" );
}

#----------------------------------------------------------------------#

sub create : Chained('base') : PathPart('create') : Args() {
    my ( $self, $c, $parent ) = @_;

    my $vlan_id = $c->req->param('vlan') || '';
    $c->stash( default_backref => $c->uri_for_action('/iprange/list') );

    my ( $message, $error );
    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }
        my $done;
        ( $done, $message, $error ) = $self->process_create($c);
        if ($done) {
            $c->flash( message => $message );

            $c->stash( default_backref =>
                    $c->uri_for_action( "iprange/view", [ $c->req->param('name') ] ) );
            $c->detach('/follow_backref');
        }
    }

    my $prefix = $c->req->param('prefix');
    my %tmpl_param;

    $tmpl_param{prefixes} =
        [ map { id => $_, label => $_, selected => $prefix && $prefix == $_, }, ( 0 .. 32 ) ];

    if ($parent) {
        my $par_obj = $c->stash->{'resultset'}->find($parent);
        $tmpl_param{p_from} = $par_obj->network ? $par_obj->network : $par_obj->from_addr;
        $tmpl_param{p_prefix} = $par_obj->netmask ? netmask2prefix( $par_obj->netmask ) : undef;
        $tmpl_param{p_to} = $par_obj->to_addr;
    }

    my @vlans_rs = $c->model('ManocDB::Vlan')->search();
    my @vlans = map { id => $_->id, name => $_->name, selected => $_->id eq $vlan_id },
        @vlans_rs;

    $tmpl_param{error_msg} = $message;
    $tmpl_param{error}     = $error;

    foreach (qw( network prefix from_addr to_addr )) {
        $tmpl_param{$_} = $c->req->param($_);
    }
    $tmpl_param{range}       = $c->req->param('name');
    $tmpl_param{parent}      = $parent;
    $tmpl_param{type_subnet} = $c->req->param('type') eq 'subnet';
    $tmpl_param{type_range}  = $c->req->param('type') eq 'range';
    $tmpl_param{vlans}       = \@vlans;

    $tmpl_param{template} = 'iprange/create.tt';

    $c->stash(%tmpl_param);
}

sub process_create : Private {
    my ( $self, $c ) = @_;
    my $name    = $c->req->param('name');
    my $type    = $c->req->param('type');
    my $vlan_id = $c->req->param('vlan');
    my $error;

    $name or $error->{name} = "Please insert range name";
    $type or return ( 0, "Please insert range type" );
    $vlan_id eq "none" and undef $vlan_id;

    my ( $network_i, $netmask_i, $from_addr_i, $to_addr_i );

    if ( $type eq 'subnet' ) {
        my $network = $c->req->param('network');
        my $prefix  = $c->req->param('prefix');

        $network             or $error->{type} = "Please insert range network";
        $prefix              or $error->{type} = "Please insert range prefix";
        check_addr($network) or $error->{type} = "Invalid network address";

        $prefix =~ /^\d+$/ and
            ( $prefix >= 0 || $prefix <= 32 ) or
            $error->{type} = "Invalid subnet prefix";

        scalar( keys(%$error) ) and return ( 0, undef, $error );

        ( $from_addr_i, $to_addr_i, $network_i, $netmask_i ) =
            Manoc::Utils::netmask_prefix2range( $network, $prefix );

        if ( $network_i != $from_addr_i ) {
            $error->{type} = "Bad network. Do you mean " . int2ip($from_addr_i) . "?";
        }
    }
    else {
        $type eq 'range' or die "Unexpected form parameter";

        my $from_addr = $c->req->param('from_addr');
        my $to_addr   = $c->req->param('to_addr');

        $from_addr or $error->{type} = "Please insert range from address";
        $to_addr   or $error->{type} = "Please insert range to address";

        check_addr($from_addr) or
            $error->{type} = "Start address not a valid IPv4 address";
        check_addr($to_addr) or
            $error->{type} = "End address not a valid IPv4 address";

        $to_addr_i   = ip2int($to_addr);
        $from_addr_i = ip2int($from_addr);

        $to_addr_i >= $from_addr_i or $error->{type} = "Invalid range";

        $network_i = $netmask_i = undef;
    }

    # check name parameter
    my ( $res, $mess );
    $name = $c->req->param('name');
    ( $res, $mess ) = check_name( $name, $c->stash->{'resultset'} );
    $res or $error->{name} = $mess;

    scalar( keys(%$error) ) and return ( 0, undef, $error );

    # check parent parameter and overlappings
    my $parent_name = $c->req->param('parent');
    if ($parent_name) {
        my $parent = $c->stash->{'resultset'}->find($parent_name);
        $parent or
            return ( 0, "Invalid parent name '$parent_name'" );

        # range should be inside its parent
        unless ( $from_addr_i >= ip2int( $parent->from_addr ) &&
            $to_addr_i <= ip2int( $parent->to_addr ) )
        {
            return ( 0,
                "Invalid range: overlaps with its parent (" . $parent->from_addr . " - " .
                    $parent->to_addr . ")" );
        }

        #Check if the range is the same of the father
        ( ( $from_addr_i == ip2int( $parent->from_addr ) ) &&
                ( $to_addr_i == ip2int( $parent->to_addr ) ) ) and
            return ( 0, "Invalid range: can't be the same as the parent range" );
    }
    else {
        $parent_name = undef;
    }

    # cannot overlap any sibling range
    my $conditions = [
        {
            'inet_aton(from_addr)' => { '<=' => $from_addr_i },
            'inet_aton(to_addr)'   => { '>=' => $from_addr_i }
        },
        {
            'inet_aton(from_addr)' => { '<=' => $to_addr_i },
            'inet_aton(to_addr)'   => { '>=' => $to_addr_i }
        },
        {
            'inet_aton(from_addr)' => { '>=' => $from_addr_i },
            'inet_aton(to_addr)'   => { '<=' => $to_addr_i }
        },
    ];
    if ( defined($parent_name) ) {
        foreach my $condition (@$conditions) {
            $condition->{parent} = $parent_name;
        }
    }

    my @rows = $c->stash->{'resultset'}->search($conditions);
    @rows and
        return ( 0,
        "Invalid range: overlaps with " . $rows[0]->name . " (" . $rows[0]->from_addr . " - " .
            $rows[0]->to_addr . ")" );

    $c->stash->{'resultset'}->create(
        {
            name      => $name,
            parent    => $parent_name,
            from_addr => int2ip($from_addr_i),
            to_addr   => int2ip($to_addr_i),
            network   => $network_i ? int2ip($network_i) : undef,
            netmask   => $netmask_i ? int2ip($netmask_i) : undef,
            vlan_id   => $vlan_id,
        }
        ) or
        return ( 0, "Impossible create subnet" );

    return ( 1, "created '$name' (" . int2ip($from_addr_i) . "-" . int2ip($to_addr_i) . ")" );
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
    my $from_addr = ip2int( $range->from_addr );
    my $to_addr   = ip2int( $range->to_addr );
    $parent = $range->parent;
    $parent and $parent = $parent->name;

    $tmpl_param{error}            = $error;
    $tmpl_param{error_msg}        = $message;
    $tmpl_param{range_name}       = $range->name;
    $tmpl_param{parent}           = $parent;
    $tmpl_param{from_addr}        = int2ip($from_addr);
    $tmpl_param{to_addr}          = int2ip($to_addr);
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

    $name1            or $error->{name1} = "Please insert name subnet 1";
    $name2            or $error->{name2} = "Please insert name subnet 2";
    $split_point_addr or $error->{split} = "Please insert split point address";

    #Check parameters
    my ( $res, $mess );
    ( $res, $mess ) = check_name( $name1, $c->stash->{'resultset'} );
    $res or $error->{name1} = $mess;
    ( $res, $mess ) = check_name( $name2, $c->stash->{'resultset'} );
    $res or $error->{name2} = $mess;

    if ( $name1 and $name1 eq $name2 ) {
        $error->{name1} = "Name Subnet 1 and Name Subnet 2 cannot be the same";
        $error->{name2} = "Name Subnet 1 and Name Subnet 2 cannot be the same";
    }

    check_addr($split_point_addr) or
        $error->{split} = "Split point address not a valid IPv4 address: $split_point_addr";

    #Retrieve subnet info
    my $from_addr = ip2int( $range->from_addr );
    my $to_addr   = ip2int( $range->to_addr );
    my $parent    = $range->parent;
    my $vlan_id   = $range->vlan_id;

    #Check split point address
    $split_point_addr = ip2int($split_point_addr);
    if ( ( $from_addr > $split_point_addr ) ||
        ( $to_addr <= $split_point_addr ) )
    {
        $error->{split} = "Split point address not inside the range";
    }

    if ( $range->children->count() ) {

        # useless:is already checked in rangelist.tmpl
        $error->{split} = "$name cannot be splitted because it is divided in subranges";
    }
    scalar( keys(%$error) ) and return ( 0, undef, $error );

    #Update DB
    $c->model('ManocDB')->txn_do(
        sub {
            $range->delete;
            $c->stash->{'resultset'}->create(
                {
                    name      => $name1,
                    parent    => $parent,
                    from_addr => int2ip($from_addr),
                    to_addr   => int2ip($split_point_addr),
                    netmask   => undef,
                    network   => undef,
                    vlan_id   => $vlan_id,
                }
                ) or
                return ( 0, "Impossible split range" );

            $c->stash->{'resultset'}->create(
                {
                    name      => $name2,
                    parent    => $parent,
                    from_addr => int2ip( $split_point_addr + 1 ),
                    to_addr   => int2ip($to_addr),
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
        if ($done) {
            $c->flash( message => "Success!! $message" );
            $c->detach('/follow_backref');

        }
    }

    my $range     = $c->stash->{'object'};
    my $from_addr = ip2int( $range->from_addr );
    my $to_addr   = ip2int( $range->to_addr );

    $parent = $range->parent;
    if ($parent) { $parent = $parent->name; }

    my @neighbours = map {
        name        => $_->name,
            from    => $_->from_addr,
            to      => $_->to_addr,
            checked => ( $neigh eq ( $_->name ) ),
    }, get_neighbour( $c->stash->{'resultset'}, $parent, $from_addr, $to_addr );

    $tmpl_param{error}      = $error;
    $tmpl_param{error_msg}  = $message;
    $tmpl_param{range_name} = $range->name;
    $tmpl_param{from_addr}  = int2ip($from_addr);
    $tmpl_param{to_addr}    = int2ip($to_addr);
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
    $neigh or return ( 0, "Please select the neighbour range" );
    $new_name or $error->{name} = "Please insert merged subnet name";

    my ( $res, $mess );
    ( $res, $mess ) = check_name( $new_name, $c->stash->{'resultset'} );
    $res or $error->{name} = "Bad merged subnet name: $mess";

    scalar( keys(%$error) ) and return ( 0, undef, $error );

    #Retrieve subnet info
    my $rs        = $c->stash->{'resultset'}->find($name);
    my $from_addr = ip2int( $rs->from_addr );
    my $to_addr   = ip2int( $rs->to_addr );
    my $parent    = $rs->parent;
    my $vlan_id   = $rs->vlan_id;

    #Retrieve neigh subnet info

    $rs = $c->stash->{'resultset'}->find($neigh);
    my $neigh_from_addr = ip2int( $rs->from_addr );
    my $neigh_to_addr   = ip2int( $rs->to_addr );

    if ($parent) {

        #Retrieve parent subnet info
        my $rs               = $c->stash->{'resultset'}->find( $parent->name );
        my $parent_from_addr = ip2int( $rs->from_addr );
        my $parent_to_addr   = ip2int( $rs->to_addr );

        #Check if the merged subnet and the parent subnet has the same range
        if (
            ( ( $from_addr == $parent_from_addr ) && ( $neigh_to_addr == $parent_to_addr ) ) ||
            ( ( $neigh_from_addr == $parent_from_addr ) &&
                ( $to_addr == $parent_to_addr ) )
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
                        $from_addr < $neigh_from_addr ? int2ip($from_addr) :
                            int2ip($neigh_from_addr)
                    ),
                    to_addr => (
                        $to_addr > $neigh_to_addr ? int2ip($to_addr) :
                            int2ip($neigh_to_addr)
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

sub check_name {
    my ( $name, $schema ) = @_;
    $name eq '' and return ( 0, "Required field" );
    $name =~ /^\w[\w-]*$/ or return ( 0, "Invalid name" );

    if ($schema) {
        $schema->find($name) and
            return ( 0, "Duplicated range name" );
    }

    return ( 1, "" );
}

sub get_neighbour {
    my ( $schema, $parent, $from_addr, $to_addr ) = @_;
    $schema->search(
        {
            parent => $parent,
            -or    => [
                { 'inet_aton(to_addr)'   => $from_addr - 1 },
                { 'inet_aton(from_addr)' => $to_addr + 1 }
            ]
        }
    );
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
