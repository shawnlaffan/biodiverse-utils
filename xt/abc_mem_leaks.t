use strict;
use warnings;
use Test::More;

use Test::LeakTrace;

use Biodiverse::Utils::XS qw/get_hash_shared_and_unique/;

use Data::Printer;

local $| = 1;

my $h1 = {1..10};
my $h2 = {5..14};

use Test::LeakTrace;
no_leaks_ok {
    my $x = get_hash_shared_and_unique ($h1, $h2);
} 'no memory leaks detected in get_hash_shared_and_unique';

my $x2 = get_hash_shared_and_unique ($h1, $h2);
p $x2;

done_testing();

