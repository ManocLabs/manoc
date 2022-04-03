use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'App::Manoc::Utils::Validate' }

{

    my ( $have, $want, $rule );

    $rule = { type  => 'scalar' };
    $want = { valid => 1 };
    $have = App::Manoc::Utils::Validate::validate( 'asd', $rule );
    is_deeply( $have, $want, "Validate scalar value" ) or diag explain $have;

    $rule = { type    => 'scalar' };
    $want = { 'error' => 'Expected scalar', 'valid' => 0 };
    $have = App::Manoc::Utils::Validate::validate( [], $rule );
    is_deeply( $have, $want, "Validate bad scalar value" ) or diag explain $have;

    $rule = { type  => 'array' };
    $want = { valid => 1 };
    $have = App::Manoc::Utils::Validate::validate( [], $rule );
    is_deeply( $have, $want, "Validate array value" ) or diag explain $have;

    $rule = { type    => 'array' };
    $want = { 'error' => 'Expected array', 'valid' => 0 };
    $have = App::Manoc::Utils::Validate::validate( {}, $rule );
    is_deeply( $have, $want, "Validate bad array value" ) or diag explain $have;

    $rule = { type  => 'hash' };
    $want = { valid => 1 };
    $have = App::Manoc::Utils::Validate::validate( {}, $rule );
    is_deeply( $have, $want, "Validate hash value" ) or diag explain $have;

    $rule = { type    => 'hash' };
    $want = { 'error' => 'Expected hash', 'valid' => 0 };
    $have = App::Manoc::Utils::Validate::validate( [], $rule );
    is_deeply( $have, $want, "Validate bad hash value" ) or diag explain $have;

}

# validate hash
{
    my $rule = {
        type  => 'hash',
        items => {
            param1 => {
                type => 'scalar',
            },
            param2 => {
                type => 'array',
            },
            param3 => {
                type => 'hash',
            }
        }
    };

    my $data = {
        param1 => 'scalar',
        param2 => [ 'a', 'b' ],
        param3 => { a => 1, b => 2 },
    };
    my $have = App::Manoc::Utils::Validate::validate( $data, $rule );
    my $want = { valid => 1 };
    is_deeply( $have, $want, "Validate hash items" ) or diag explain $have;
}

{
    my $rule = {
        type  => 'hash',
        items => {
            param1 => {
                type => 'scalar',
            },
            param2 => {
                type => 'array',
            },
            param3 => {
                type => 'hash',
            }
        }
    };

    my $data = {
        param1 => 'scalar1',
        param2 => 'not array',
        param3 => 'not a hash',
    };
    my $have = App::Manoc::Utils::Validate::validate( $data, $rule );
    my $want = {
        'errors' => [
            {
                'error' => 'Expected array',
                'field' => 'param2'
            },
            {
                'error' => 'Expected hash',
                'field' => 'param3'
            }
        ],
        'valid' => 0
    };

    # sort hash to help is_deeply
    if ( $have->{errors} ) {
        my @sorted_errors = sort { $a->{field} cmp $b->{field} } @{ $have->{errors} };
        $have->{errors} = \@sorted_errors;
    }

    is_deeply( $have, $want, "Validate hash items, type mismatch" ) or diag explain $have;
}

{
    my $rule = {
        type  => 'hash',
        items => {
            param1 => {
                type    => 'array',
                arrayof => {
                    type => 'scalar'
                }
            },
            param2 => {
                arrayof => {
                    type => 'scalar'
                }
            },
        }
    };

    my $data = {
        param1 => [ 'scalar1', 'scalar2' ],
        param2 => [ 'scalar2', { err => 'orr' }, [ 'err', 'orr' ] ],
    };
    my $have = App::Manoc::Utils::Validate::validate( $data, $rule );
    my $want = {
        'errors' => [
            {
                'error' => 'Expected scalar',
                'field' => 'param2.1'
            },
            {
                'error' => 'Expected scalar',
                'field' => 'param2.2'
            }
        ],
        'valid' => 0
    };

    # sort hash to help is_deeply
    if ( $have->{errors} ) {
        my @sorted_errors = sort { $a->{field} cmp $b->{field} } @{ $have->{errors} };
        $have->{errors} = \@sorted_errors;
    }

    is_deeply( $have, $want, "Validate hash items, array recursion" ) or diag explain $have;
}

{
    my $rule = {
        type  => 'hash',
        items => {
            param1 => {
                type => 'scalar',
            },
            param2 => {
                type     => 'scalar',
                required => 1,
            },
            param3 => {
                type     => 'scalar',
                required => 0,
            }
        }
    };

    my $data = { param1 => 'test' };
    my $have = App::Manoc::Utils::Validate::validate( $data, $rule );
    my $want = {
        'errors' => [
            {
                'error' => 'Missing required field',
                'field' => 'param2'
            }
        ],
        'valid' => 0
    };

    is_deeply( $have, $want, "Validate hash - missing element" ) or diag explain $have;
}

{
    my $rule = {
        type  => 'hash',
        items => {
            param1 => {
                type => 'scalar',
            },
        },
    };

    my $data = {
        param1 => 'test',
        param2 => 'test',
    };
    my $have = App::Manoc::Utils::Validate::validate( $data, $rule );
    my $want = {
        'errors' => [
            {
                'error' => 'Unexpected field',
                'field' => 'param2'
            }
        ],
        'valid' => 0
    };

    is_deeply( $have, $want, "Validate hash - unknown element" ) or diag explain $have;
}

done_testing();

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
