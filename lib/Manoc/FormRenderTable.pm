# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::FormRenderTable;
# ABSTRACT: render a form with a table layout

use Moose::Role;

with 'HTML::FormHandler::Render::Simple' => { -excludes =>
        [ 'render', 'render_select', 'render_field_struct', 'render_end', 'render_start', 'render_text'  ] };

sub render_start {
    my $self = shift;
    my $output = $self->html_form_tag . "<table class=\"ui-widget-content ui-corner-all\">\n";
    return $output;
}

sub render_end {
    my $self   = shift;
    my $output .= "</table>\n";
    $output .= "</form>\n";
    return $output;
}

sub render_text {
  my ( $self, $field ) = @_;

  my $output = '<input type="text" name="';
  $output .= $field->html_name . '"';
  $output .= ' id="' . $field->id . '"';
  $output .= ' size="' . $field->size . '"' if $field->size;
  $output .= ' maxlength="' . $field->maxlength . '"' if $field->maxlength;

  my $value = ' value="' . $field->html_filter($field->fif) . '"';
  if (defined($field) and $field->fif ne ''  ) {
    if ( ref($field->fif) and $field->fif->isa("Manoc::IpAddress") ) {
      $value = ' value="' . $field->html_filter($field->fif->address) . '"';
    }
  }
  $output .= $value;

  $output .= $self->_add_html_attributes( $field );
  $output .= ' />';
  return $output;
}

sub render_field_struct {
    my ( $self, $field, $rendered_field, $class ) = @_;
    my $output = qq{\n<tr$class>};
      
    my $l_type =
        defined $self->get_label_type( $field->widget ) ?
        $self->get_label_type( $field->widget ) :
        '';
    if ( $l_type eq 'label' ) {
        $output .= '<td>' . $self->_label($field) . '</td>';
    }
    elsif ( $l_type eq 'legend' ) {
        $output .= '<td>' . $self->_label($field) . '</td></tr>';
    }
    if ( $l_type ne 'legend' ) {
        $output .= '<td>';
    }
    $output .= $rendered_field;
    $output .= qq{\n<span class="error_message">$_</span>} for $field->all_errors;
    if ( $l_type ne 'legend' ) {
        $output .= "</td></tr>\n";
    }
    return $output;
}

sub render_select {
    my ( $self, $field ) = @_;

    my $output = '<select name="' . $field->html_name . '"';
    $output .= ' id="' . $field->id . '"';
    $output .= ' multiple="multiple"' if $field->multiple == 1;
    $output .= ' size="' . $field->size . '"' if $field->size;
    $output .= $self->_add_html_attributes($field);
    $output .= '>';
    my $index = 0;
    if ( $field->empty_select ) {
        $output .=
            '<option value="">' . $field->_localize( $field->empty_select ) . '</option>';
    }
    foreach my $option ( @{ $field->options } ) {
        $output .= '<option value="' . $field->html_filter( $option->{value} ) . '" ';
        $output .= 'id="' . $field->id . ".$index\" ";
        if ( $field->fif ) {
            if ( $field->multiple == 1 ) {
                my @fif;
                if ( ref $field->fif ) {
                    @fif = @{ $field->fif };
                }
                else {
                    @fif = ( $field->fif );
                }
                foreach my $optval (@fif) {
                    $output .= 'selected="selected"'
                        if $optval eq $option->{value};
                }
            }
            else {
                $output .= 'selected="selected"'
                    if $option->{value} eq $field->fif;
            }
        }
        else {
            $output .= 'selected="selected"' if $option->{selected};
        }
        my $label =
            $field->localize_labels ? $field->_localize( $option->{label} ) : $option->{label};
        $output .= '>' . $field->html_filter($label) . '</option>';
        $index++;
    }
    $output .= '</select>';
    return $output;
}

sub render {
    my $self = shift;

    my @buttons;

    my $output = $self->render_start;

    foreach my $field ( $self->sorted_fields ) {
        if ( $field->type eq 'Submit' ) {
            push @buttons, $field;
        }
        else {
            $output .= $self->render_field($field);
        }
    }

    $output .= $self->render_buttons( \@buttons );

    $output .= $self->render_end;

    return $output;
}

sub render_buttons {
    my ( $self, $buttons ) = @_;

    my $output = "<tr><td colspan=\"2\">";

    foreach my $b (@$buttons) {
        $output .= $self->render_submit($b);
    }

    $output .= "</td></tr>";
    return $output;
}

use namespace::autoclean;
1;
