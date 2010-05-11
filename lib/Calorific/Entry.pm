package Calorific::Entry;

use Mouse;
use Calorific::Recipe;
use Calorific::Util qw/ parse_date /;

has [qw/ date description recipe /] => (is => 'ro');

sub parse
{
    my ($class, $key, $parts) = @_;
    my ($date, $desc) = split(/\s+/, $key, 2);
    $date = parse_date($date);

    my @components;

    unless(ref($parts) eq 'ARRAY') {
        $parts = [$parts];
    }

    for my $part ( @$parts ) {
        if (ref($part) eq 'HASH') {
            my $label = [keys %$part]->[0];
            push @components, Calorific::Recipe->parse($label, $part->{$label});
        } elsif (!ref($part) || ref($part) eq '') {
            push @components, Calorific::Recipe->parse($part, []);
        }
    }

    return $class->new(
        date => $date,
        description => $desc,
        recipe => Calorific::Recipe->new(
            count      => 1,
            label      => '',
            components => \@components,
        ),
    );
}

sub value
{
    my ($self, $recipe_xref) = @_;
    return $self->recipe()->value(1, $recipe_xref);
}

__PACKAGE__->meta->make_immutable;

1;
