use Test::More;

use List::Util qw /max/;
use Math::Random::MT::Auto;
use Test::LeakTrace;

use Biodiverse::Utils::XS qw/get_hash_shared_and_unique/;

my $prng = Math::Random::MT::Auto->new;

local $| = 1;

my %h1 = (ac => 1, bc => 2);
my %h2 = (ac => 1, cc => 2);

use Test::LeakTrace;
no_leaks_ok {
    my $x = run_the_thing ();
    #say join ':', values %$x;
} 'no memory leaks detected in get_hash_shared_and_unique';


done_testing();


sub run_the_thing {
    my $h = get_hash_shared_and_unique(\%h1, \%h2);
}
