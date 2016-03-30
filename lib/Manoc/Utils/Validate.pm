# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Utils::Validate;
use strict;
use warnings;
use Carp 'croak';

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/
        validate
        /;
}

=head1 NAME

Manoc::Utils::Validate - Helpers for data validation.

=encoding utf8

=head1 DESCRIPTION

These package contains helpers for data validation.

=head1 METHODS

=cut

=head2 validate($value, \%rule, %options)

Validate $value using %rule. Rule can have the following clauses:

=over 4

=item type

On of scalar, array, hash.

=item arrayof

A rule to valudidate each element of an array value. No effects for other values of other types.

=item items

An hash reference to validate hash values, made of ('name_of_the_key', \%rule) pairs. See also required.

=item required

For rules used to validate hash values, set the element as required.

=item ignore_extra_items

When validating an hash values with items rules, do not return errors for unrecognized keys.

=back

=cut

sub validate {
    my $value   = shift;
    my $rule    = shift;
    my %options = @_;

    # get value type
    my $ref = ref($value);
    my $type;
    if ( !$ref ) {
        $type = 'scalar';
    }
    elsif ( $ref eq 'HASH' ) {
        $type = 'hash';
    }
    elsif ( $ref eq 'ARRAY' ) {
        $type = 'array';
    }
    else {
        return {
            valid => 0,
            error => "Unsupported data type",
        };
    }

    if ( !exists( $rule->{type} ) and $rule->{arrayof} ) {
        $rule->{type} = 'array';
    }

    # check type if required, return immediately on error
    if ( $rule->{type} ) {
        my $expected_type = $rule->{type};
        if ( $expected_type ne 'any' && $expected_type ne $type ) {
            return {
                valid => 0,
                error => "Expected $expected_type",
            };
        }
    }
    else {
        croak 'type rule is required';
    }

    # recurse if required
    my $validation;
    if ( $type eq 'array' ) {
        $validation = _validate_array( $value, $rule, %options );
    }
    elsif ( $type eq 'hash' ) {
        $validation = _validate_hash( $value, $rule, %options );
    }

    if ( $validation && $validation->{valid} == 0 ) {
        return $validation;
    }
    return { valid => 1 };
}

# recurse into elements
sub _validate_array {
    my $data    = shift;
    my $rule    = shift;
    my %options = @_;

    my $errors = [];

    # loop on elements if required by items
    if ( my $item_rule = $rule->{arrayof} ) {
        my $i = 0;

        foreach my $element (@$data) {
            my $validation = validate( $element, $item_rule, %options );
            if ( !$validation->{valid} ) {
                if ( $validation->{error} ) {
                    push @$errors, { field => $i, error => $validation->{error} };
                }
                else {
                    foreach my $e ( @{ $validation->{errors} } ) {
                        $e->{field} = $i . "." . $e->{field};
                        push @$errors, $e;
                    }
                }
            }
            $i++;
        }
    }

    if ( scalar(@$errors) ) {
        return { valid => 0, errors => $errors };
    }
    else {
        return { valid => 1 };
    }
}

# recurse into hash
sub _validate_hash {
    my $data    = shift;
    my $rule    = shift;
    my %options = @_;

    my $errors = [];

    if ( my $item_rules = $rule->{items} ) {

    ITEM:
        while ( my ( $field, $item_rule ) = each(%$item_rules) ) {
            if ( !exists $data->{$field} ) {
                # give error if it is required
                if ( $item_rule->{required} ) {
                    push @$errors,
                        {
                        field => $field,
                        error => "Missing required field",
                        };
                }

            }
            else {
                # check value
                my $value = $data->{$field};

                my $validation = validate( $value, $item_rule, %options );
                if ( !$validation->{valid} ) {
                    if ( $validation->{error} ) {
                        push @$errors, { field => $field, error => $validation->{error} };
                    }
                    else {
                        foreach my $e ( @{ $validation->{errors} } ) {
                            $e->{field} = $field . "." . $e->{field};
                            push @$errors, $e;
                        }
                    }
                }
            }
        }    # end ITEM loop

        # check for unknown items
        if ( !$rule->{ignore_extra_items} ) {
            for my $k ( keys(%$data) ) {

                next if exists( $item_rules->{$k} );

                push @$errors,
                    {
                    field => $k,
                    error => "Unexpected field",
                    };
            }
        }
    }

    return { valid => scalar(@$errors) == 0 ? 1 : 0, errors => $errors };
}

=head1 AUTHOR

Gabriele

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
