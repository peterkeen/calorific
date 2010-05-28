package Calorific;

our $VERSION = '0.01';

use Mouse;
use File::Slurp qw/ read_file /;
use YAML::XS;
use Perl6::Form;
use Term::ANSIColor;

use Calorific::Recipe;
use Calorific::Entry;
use Calorific::Util qw/ add_hashes parse_date /;

has 'filename' => (
    is       => 'ro',
    required => 1,
);

has 'recipes'  => (
    is      => 'ro',
    traits  => [ 'Hash' ],
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
    handles => {
        get_recipe => 'get',
        set_recipe => 'set',
    },
);

has 'goals' => (
    is      => 'ro',
    traits  => [ 'Hash' ],
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
    handles => {
        get_goal => 'get',
        set_goal => 'set',
    },
);

has 'entries' => (
    is      => 'rw',
    traits  => [ 'Array' ],
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
    handles => {
        add_entries      => 'push',
        filtered_entries => 'grep',
        num_entries      => 'count',
        all_entries      => 'elements',
        sorted_entries   => 'sort',
    },
);

has 'begin_date' => (is => 'ro');
has 'end_date'   => (is => 'ro');

sub BUILD
{
    my $self = shift;
    my $contents = read_file($self->filename());
    my $things = Load($contents);

    for my $thing ( @$things ) {
        my ($key) = keys %$thing;
        if (_key_is_recipe($key)) {
            my ($count, $label) = split(/\s+/, $key, 2);
            $self->set_recipe($label, Calorific::Recipe->parse(
                $key,
                $thing->{$key}
            ));
        } elsif (_key_is_entry($key)) {
            $self->add_entries(Calorific::Entry->parse(
                $key,
                $thing->{$key}
            ));
        } elsif (_key_is_goals($key)) {
            for my $goal ( @{ $thing->{$key} }) {
                my ($nutrient) = keys %$goal;
                $self->set_goal($nutrient, $goal->{$nutrient});
            }
        } else {
            die "invalid recipe or entry key '$key'";
        }
    }
}

sub detail_report
{
    my $self = shift;
    return join(
        '',
        map {
            $self->_format_entry($_->date(), $_->description, $_->value($self->recipes()), 1)
        }
        $self->entries_in_date_range()
    );
}

sub daily_report
{
    my $self = shift;
    my $aggregates = $self->_daily_aggregates();
    return join(
        '',
        map {
            $self->_format_entry($_, '<total>', $aggregates->{$_});
        }
        sort keys %$aggregates);
}

sub weekly_report
{
    my $self = shift;
    my $aggregates = $self->_daily_aggregates();

    my %count_by_week;
    my %sum_by_week;

    for my $d (keys %$aggregates) {
        my $date = parse_date($d);
        my $week = $date->subtract( days => $date->day_of_week - 1 );
        $count_by_week{$week}++;
        $sum_by_week{$week} = add_hashes($aggregates->{$d}, $sum_by_week{$week} || {});
    }

    my %avg_by_week;
    for my $week ( keys %sum_by_week ) {
        for my $key ( keys %{ $sum_by_week{$week} }) {
            $avg_by_week{$week}{$key} = $sum_by_week{$week}{$key} / $count_by_week{$week};
        }
    }

    return join(
        '',
        map {
            $self->_format_entry($_, '<total>', $avg_by_week{$_});
        }
        sort keys %avg_by_week);
}

sub entries_in_date_range
{
    my $self = shift;

    return $self->filtered_entries(sub {
        return 0 if $self->begin_date() && $_->date() < $self->begin_date();
        return 0 if $self->end_date()   && $_->date() > $self->end_date();
        return 1;
    });
}

sub _daily_aggregates
{
    my $self = shift;
    my %days;
    for my $entry ( $self->entries_in_date_range() ) {
        my $date = $entry->date()->strftime('%F');
        $days{$date} = add_hashes($entry->value($self->recipes()), $days{$date} || {});
    }
    return \%days;
}

sub _format_entry
{
    my ($self, $datetime, $description, $value, $no_color) = @_;
    my ($date) = split(/T/, $datetime);
    my $string = '';
    my @keys = sort keys %$value;
    my $first = shift @keys;
    my $val_format = $no_color ? '{>>>>}' : '{>>>>>>>>>>>>>}';
    $string .= form "{<<<<<<<<} {<<<<<<<<<<<<<<<<<<} ${val_format} {<<<<<<<<<<}\n",
               $date, $description, $self->_format_value($value->{$first}, $first, $no_color), $first;
    for my $key (@keys) {
        $string .= form ' ' x 32 . "${val_format} {<<<<<<<<<<}\n", $self->_format_value($value->{$key}, $key, $no_color), $key;
    }
    return $string;
}

sub _format_value
{
    my ($self, $value, $nutrient, $no_color) = @_;

    my ($min, $max);
    my $goal = $self->get_goal($nutrient);
    if (!$goal || $no_color) {
        return int($value)
    }

    if (ref($goal) eq 'ARRAY') {
        ($min, $max) = @$goal;
    } else {
        $min = 0;
        $max = $goal;
    }

    my $color = $value >= $min && $value <= $max
        ? "green"
        : "red"
    ;

    return colored(int($value), $color);
}

sub _key_is_recipe
{
    my $key = shift;
    return $key =~ /^[\d\.]+\s+/;
}

sub _key_is_entry
{
    my $key = shift;
    return $key =~ /^\d{4}-\d{2}-\d{2}\s+/;
}

sub _key_is_goals
{
    my $key = shift;
    return $key =~ /^goals$/i;
}

__PACKAGE__->meta->make_immutable;

1;
