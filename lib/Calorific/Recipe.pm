package Calorific::Recipe;

use Mouse;
use Calorific::Util qw/ add_hashes /;

has [qw/ count label components /] => (is => 'ro');

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
            my $recipe = $recipe_xref->{$label};
            my $val = $recipe->value($self->count(), $recipe_xref);

            return { map { $_ => $val->{$_} * (1 / $recipe->count()) * $count } keys %$val };
        } else {
            return {$label => $count * $self->count};
        }
    } else {
        my $value_by_label = {};

        for my $comp ( @{ $self->components() } ) {
            $value_by_label = add_hashes($value_by_label, $comp->value($count, $recipe_xref));
        }

        return $value_by_label;
    }
}

__PACKAGE__->meta->make_immutable;

1;
