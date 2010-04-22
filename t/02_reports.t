use strict;
use Test::More tests => 5;
use Calorific;
use File::Temp qw/ tempfile /;

my @files_to_cleanup;

sub write_to_tmpfile
{
    my $contents = shift;
    my (undef, $filename) = tempfile();
    open(my $fh, ">", $filename) or die "cannot open $filename: $!";
    print $fh $contents;
    close $fh;
    push @files_to_cleanup, $filename;
    return $filename;
}

my $file1 = write_to_tmpfile(<<HERE);
- 2010-01-01 breakfast:
    - 1 egg:    90 kcal
    - 1 toast: 100 kcal
HERE

is (Calorific->new(filename => $file1)->daily_report(), <<HERE, "daily report");
2010-01-01 <total>                  190 kcal
HERE

is (Calorific->new(filename => $file1)->detail_report(), <<HERE, "simple detail report");
2010-01-01 breakfast                190 kcal
HERE


my $file2 = write_to_tmpfile(<<HERE);
- 1 egg:   [  90 kcal, 10 protein ]
- 1 toast: [ 100 kcal,  8 protein ]

- 2010-01-01 breakfast:
    - 1 egg
    - 1 toast

- 2010-01-01 lunch:
    - 3 toast

- 2010-01-02 breakfast:
    - 1 egg
HERE

is (Calorific->new(filename => $file2)->daily_report(), <<HERE, "complex daily report");
2010-01-01 <total>                  490 kcal
                                     42 protein
2010-01-02 <total>                   90 kcal
                                     10 protein
HERE

is (Calorific->new(filename => $file2)->detail_report(), <<HERE, "complex detail report");
2010-01-01 breakfast                190 kcal
                                     18 protein
2010-01-01 lunch                    300 kcal
                                     24 protein
2010-01-02 breakfast                 90 kcal
                                     10 protein
HERE

my $file3 = write_to_tmpfile(<<HERE);
- 1 egg:   [  90 kcal, 10.2 protein ]
- 1 toast: [ 100 kcal,  8.5 protein ]

- 2010-01-01 breakfast:
    - 1 egg
    - 1 toast

- 2010-01-01 lunch:
    - 3 toast

- 2010-01-02 breakfast:
    - 1 egg
HERE

is (Calorific->new(filename => $file3)->daily_report(), <<HERE, "rounds numbers in report");
2010-01-01 <total>                  490 kcal
                                     44 protein
2010-01-02 <total>                   90 kcal
                                     10 protein
HERE


unlink for @files_to_cleanup;
