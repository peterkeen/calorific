package App::Calorific::Util;

use strict;
use base 'Exporter';

our @EXPORT_OK = qw(
    add_hashes
    avg_hashes
    parallel_for_each_key
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
    return parallel_for_each_key( sub { return $_[1] + $_[2] }, $left, $right);
}

sub avg_hashes
{
    my %sum;
    my %count;

    parallel_for_each_key( sub {
        $count{$_[0]}++;
        $sum{$_[0]} = $_[1] + $_[2];
    }, @_ );

    return parallel_for_each_key( sub {
        return $_[1] / $_[2];
    }, \%sum, \%count);
}

1;
