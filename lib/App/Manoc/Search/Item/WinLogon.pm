package App::Manoc::Search::Item::WinLogon;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item::Group';

has '+item_type' => ( default => 'logon' );

no Moose;
__PACKAGE__->meta->make_immutable;
