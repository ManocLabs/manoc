
# Generated automatically with HTML::FormHandler::Generator::DBIC
# Using following commandline:
# form_generator.pl --rs_name=VirtualInfr --schema_name=Manoc::DB --db_dsn=dbi:SQLite:manoc.db

package Manoc::Form::VirtualInfr;

use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';

has '+item_class' => ( default => 'VirtualInfr' );

has_field 'version'  => ( type => 'Text',     size     => 32, );
has_field 'platform' => ( type => 'Text',     size     => 32, );
has_field 'address'  => ( type => 'Text',     size     => 15, required => 1, );
has_field 'name'     => ( type => 'TextArea', required => 1, );

has_field 'submit' => ( widget => 'Submit', );

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;

