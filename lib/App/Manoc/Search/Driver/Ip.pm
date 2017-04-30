package App::Manoc::Search::Driver::Ip;

use Moose;

##VERSION

use App::Manoc::Search::Item::IpAddr;

extends 'App::Manoc::Search::Driver';

sub search_note {
    my ( $self, $query, $result ) = @_;

    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    my $it = $schema->resultset('Ip')
        ->search( { notes => { '-like' => $pattern } }, { order_by => 'notes' }, );
    while ( my $e = $it->next ) {
        my $item = App::Manoc::Search::Item::IpAddr->new(
            {
                match => $e->ipaddr->address,
                addr  => $e->ipaddr->address,
                text  => $e->notes,
            }
        );
        $result->add_item($item);
    }
}

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern  = $query->sql_pattern;
    my $schema   = $self->engine->schema;
    my @ip_infos = qw(description assigned_to phone email);

    foreach my $k (@ip_infos) {
        $it = $schema->resultset('Ip')
            ->search( { $k => { '-like' => $pattern } }, { order_by => 'ipaddr' } );
        while ( $e = $it->next ) {
            my $item = App::Manoc::Search::Item::IpAddr->new(
                {
                    match => $e->$k,
                    addr  => $e->ipaddr->address,
                    text  => $e->$k
                }
            );
            $result->add_item($item);
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
