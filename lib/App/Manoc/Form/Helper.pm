package App::Manoc::Form::Helper;

use strict;
use warnings;

##VERSION

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/bs_block_field_helper/;
}

sub bs_block_field_helper {
    my $input_width;
    my $label_width;
    if ( @_ == 1 ) {
        my $args = shift;
        $input_width = $args->{input};
        $label_width = $args->{label};
    }
    else {
        $input_width = shift;
        $label_width = shift;
    }

    return (
        do_wrapper => 0,
        tags       => {
            before_element => '<div class="col-sm-' . $input_width . '">',
            after_element  => '</div>'
        },
        label_class => ["col-sm-${label_width}"],
    );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
