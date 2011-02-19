# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::VersionType;
use Moose::Util::TypeConstraints;

subtype 'Version' => as 'Str' => where { $_ =~ m/^\d\.\d{6}$/ } => message {
    'Version number must have the form: <version_number>{1}.<major>{3}<minor>{3} (e.g. 2.320120)';
};

no Moose::Util::TypeConstraints;

