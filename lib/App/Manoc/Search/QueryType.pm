package App::Manoc::Search::QueryType;

use Moose::Util::TypeConstraints;

##VERSION

@App::Manoc::Search::QueryType::TYPES =
    qw(inventory building rack device server logon ipaddr macaddr note subnet);

enum 'QueryType' => \@App::Manoc::Search::QueryType::TYPES;

no Moose::Util::TypeConstraints;
