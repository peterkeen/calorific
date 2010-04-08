package Calorific;

use Moose;
use File::Slurp qw/ read_file /;
use YAML::XS;
use Perl6::Form;

use Calorific::Recipe;
use Calorific::Entry;
use Calorific::Util qw/ add_hashes /;

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

has 'entries' => (
    is      => 'rw',
    traits  => [ 'Array' ],
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
    handles => {
        add_entries    => 'push',
        filter_entries => 'grep',
        num_entries    => 'count',
        all_entries    => 'elements',
        sorted_entries => 'sort',
    },
);

sub BUILD
{
    my $self = shift;
    my $contents = read_file($self->filename());
    my $recipes_and_entries = Load($contents);

    for my $recipe_or_entry ( @$recipes_and_entries ) {
        my ($key) = keys %$recipe_or_entry;
        if (_key_is_recipe($key)) {
            my ($count, $label) = split(/\s+/, $key, 2);
            $self->set_recipe($label, Calorific::Recipe->parse(
                $key,
                $recipe_or_entry->{$key}
            ));
        } elsif (_key_is_entry($key)) {
            $self->add_entries(Calorific::Entry->parse(
                $key,
                $recipe_or_entry->{$key}
            ));
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
            $self->_format_entry($_->date(), $_->description, $_->value($self->recipes()))
        }
        $self->all_entries()
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
        sort keys %$aggregates
    );
}

sub _daily_aggregates
{
    my $self = shift;
    my %days;
    for my $entry ( $self->all_entries() ) {
        my $date = $entry->date();
        $days{$date} = add_hashes($entry->value($self->recipes()), $days{$date} || {});
    }
    return \%days;
}

sub _format_entry
{
    my ($self, $date, $description, $value) = @_;
    my $string = '';
    my @keys = sort keys %$value;
    my $first = shift @keys;
    $string .= form "{<<<<<<<<} {<<<<<<<<<<<<<<<<<<} {>>>>>} {<<<<<<<<<<}\n",
               $date, $description, $value->{$first}, $first;
    for my $key (@keys) {
        $string .= form ' ' x 32 . "{>>>>>} {<<<<<<<<<<}\n", $value->{$key}, $key;
    }
    return $string;
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

__PACKAGE__->meta->make_immutable;

1;
