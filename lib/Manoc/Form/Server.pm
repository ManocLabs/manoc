# Skeleton Generated automatically with
# HTML::FormHandler::Generator::DBIC Using following commandline:

# Form_generator.pl --rs_name=Server --schema_name=Manoc::DB
# --db_dsn=dbi:SQLite:manoc.db
Package Manoc::Form::Server;

use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';

has '+item_class' => ( default => 'Server' );

has_field 'on_hypervisor' => ( type => 'Boolean', );

has_field 'hosted_virtual_infr' => ( type => 'Select', );
has_field 'on_virtual_infr'     => ( type => 'Select', );
has_field 'on_hypervisor'       => ( type => 'Select', );

has_field 'os_ver'  => ( type => 'Text',     size     => 32, );
has_field 'os'      => ( type => 'Text',     size     => 32, );
has_field 'address' => ( type => 'Text',     size     => 15, required => 1, );
has_field 'name'    => ( type => 'TextArea', required => 1, );

has_field 'asset'  => ( type   => 'Select', );
has_field 'submit' => ( widget => 'Submit', );

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;
