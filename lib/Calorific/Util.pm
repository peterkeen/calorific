package Calorific::Util;

use strict;
use base 'Exporter';

use DateTime::Format::Natural;

our @EXPORT_OK = qw(
    add_hashes
    avg_hashes
    parallel_for_each_key
    parse_date
);

sub parallel_for_each_key
{
    my ($code, $left, $right) = @_;

    my %keys = map { $_ => 1 } (keys %$left, keys %$right);

    my %return;

    for my $key ( keys %keys ) {
        $return{$key} = $code->($key, $left->{$key}, $right->{$key});
    }

    return \%return;
}

sub add_hashes
{
    my ($left, $right) = @_;
    return parallel_for_each_key( sub { return ($_[1] || 0) + ($_[2] || 0) }, $left, $right);
}

sub parse_date
{
    my $date = shift;
    return undef unless defined($date);
    return DateTime::Format::Natural->new()->parse_datetime($date);
}

1;
