package Calorific::Recipe;

use Mouse;

has 'count'      => (is => 'rw');
has 'label'      => (is => 'rw');
has 'components' => (is => 'rw');

sub parse
{
    my ($class, $key, $parts) = @_;

    unless(ref($parts) eq 'ARRAY') {
        $parts = [$parts];
    }

    my ($count, $label) = split(/\s+/, $key, 2);
    my @components;

    for my $part ( @$parts ) {
        if (ref($part) eq 'HASH') {
            my $part_label = [keys %$part]->[0];
            my $part_comps = $part->{$part_label};
            push @components, $class->parse($part_label, $part_comps);
        } elsif (!ref($part) || ref($part) eq '') {
            push @components, $class->parse($part, []);
        } else {
            die "I have no idea what to do with a " . ref($part) . " in key $key";
        }
    }

    return $class->new(
        count      => $count,
        label      => $label,
        components => \@components,
    );
}

sub value
{
    my ($self, $count, $recipe_xref) = @_;
    my $label = $self->label;

    if (scalar @{ $self->components() } == 0) {
        if (defined $recipe_xref->{$label}) {
            return $recipe_xref->{$label}->value($self->count(), $recipe_xref);
        } else {
            return {$label => $self->count};
        }
    } else {
        my $value_by_label = {};
        for my $comp ( @{ $self->components() } ) {
            $value_by_label = add_hashes($value_by_label, $comp->value($comp->count, $recipe_xref));
        }
        return $value_by_label;
    }
}

sub add_hashes
{
    my ($left, $right) = @_;
    my %result;

    for my $key ( keys %$right, keys %$left ) {
        my $left_value  = defined $left->{$key}  ? $left->{$key}  : 0;
        my $right_value = defined $right->{$key} ? $right->{$key} : 0;
        $result{$key} = $left_value + $right_value;
    }

    return \%result;
}

1;
