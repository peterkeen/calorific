use strict;
use Test::More tests => 4;
use Calorific::Recipe;

is_deeply (
    Calorific::Recipe->parse('1 egg', [ '90 kcal' ])->value(1, {}),
    { kcal => 90 },
    "simple recipe"
);

is_deeply (
    Calorific::Recipe->parse('1 eggy toast', [ '1 egg', '1 toast' ])->value(1, {
        egg   => Calorific::Recipe->parse('1 egg',   [  '90 kcal' ]),
        toast => Calorific::Recipe->parse('1 toast', [ '100 kcal' ]),
    }),
    { kcal => 190 },
    "nested recipe"
);

is_deeply (
    Calorific::Recipe->parse('1 eggy toast', [ '1 egg', '1 toast' ])->value(1, {
        egg   => Calorific::Recipe->parse('1 egg',   [  '90 kcal', '8 prot' ]),
        toast => Calorific::Recipe->parse('1 toast', [ '100 kcal', '5 prot' ]),
    }),
    { kcal => 190, prot => 13 },
    "multiple base components"
);

is_deeply (
    Calorific::Recipe->parse('1 egg', [ '90 kcal' ])->value(2.5, {}),
    { kcal => 225 },
    "multiply recipe"
);
