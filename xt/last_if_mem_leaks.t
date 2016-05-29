use Test::More;

use List::Util qw /max/;
use Math::Random::MT::Auto;
use Test::LeakTrace;

use Biodiverse::Utils::XS qw/add_hash_keys_until_exists copy_values_from/;


#use rlib;
#use Biodiverse::Bencher qw/add_hash_keys_lastif copy_values_from/;

my $prng = Math::Random::MT::Auto->new;

local $| = 1;

my $n = 20;   #  depth of the paths
my $m = 1800;  #  number of paths
my $r = $n - 1;    #  how far to be the same until (irand)
my $subset_size = int ($m/4);
my %path_arrays;  #  ordered keys
my %path_hashes;  #  unordered key-value pairs
my %len_hash;

$n = 5;
$m = 8;
$r = 0;
$subset_size = $n;

#  generate a set of paths 
foreach my $i (0 .. $m) {
    my $same_to = max (1, int $prng->rand($r));
    my @a;
    #@a = map {((1+$m)*$i*$n+$_), 1} (0 .. $same_to);
    @a = map {$_ => $_} (0 .. $same_to);
    push @a, map {((1+$m)*$i*$n+$_) => $_} ($same_to+1 .. $n);
    #say join ' ', @a;
    my %hash = @a;
    $path_hashes{$i} = \%hash;
    $path_arrays{$i} = [reverse sort {$a <=> $b} keys %hash];
    
    @len_hash{keys %hash} = values %hash;
}


use Test::LeakTrace;
no_leaks_ok {
    my $x = inline_assign (\%path_arrays);
    #say join ':', values %$x;
} 'no memory leaks detected in inline_assign';


done_testing();


sub inline_assign {
    my $paths = shift;

    my %combined;

    foreach my $path (values %$paths) {
        add_hash_keys_until_exists (\%combined, $path);
    }

    copy_values_from (\%combined, \%len_hash);

    return \%combined;
}
