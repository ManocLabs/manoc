# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::VersionType;
use Moose::Util::TypeConstraints;

subtype 'Version' => as 'Str' => where { $_ =~ m/^(\d{8}|\d{1}\.\d{6})$/  } => message {
    'Version number must have the form: <year>{4}<month>{2}<day>{2} (e.g. 20000101)';
};

no Moose::Util::TypeConstraints;

