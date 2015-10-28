use Test::More;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

use List::Util qw /max/;
use Math::Random::MT::Auto;

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

#$n = 5;
#$m = 8;
#$r = 0;
#$subset_size = $n;

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





#  only really need to test xs_assign - the rest is useful paranoia
my $sliced = slice (\%path_hashes);
my $forled = pp_assign (\%path_arrays);
my $slice2 = slice_mk2 (\%path_hashes);
my $inline = xs_assign (\%path_arrays);

#foreach my $key (keys %len_hash) {
#    $len_hash{$key}++;
#}

is_deeply ($sliced, \%len_hash, 'slice results are the same');
is_deeply ($slice2, \%len_hash, 'slice2 results are the same');
is_deeply ($forled, \%len_hash, 'forled results are the same');
is_deeply ($inline, \%len_hash, 'inline results are the same');


done_testing;



sub slice {
    my $paths = shift;
    
    my %combined;
    
    foreach my $path (values %$paths) {
        @combined{keys %$path} = values %$path;
    }
    #  next line is necessary when the paths
    #  have different values from %combined,
    #  albeit the initial use case was the same
    @combined{keys %combined} = @len_hash{keys %combined};

    return \%combined;
}

#  assign values at end
sub slice_mk2 {
    my $paths = shift;
    
    my %combined;
    
    foreach my $path (values %$paths) {
        @combined{keys %$path} = undef;
    }
    
    @combined{keys %combined} = @len_hash{keys %combined};
    
    return \%combined;
}

#sub for_last {
#    my $paths = shift;
#    
#    
#    #  initialise
#    my %combined;
#
#  LIST:
#    foreach my $list (values %$paths) {
#        if (!scalar keys %combined) {
#            @combined{@$list} = undef;
#            next LIST;
#        }
#        
#        foreach my $key (@$list) {
#            last if exists $combined{$key};
#            $combined{$key} = undef;
#        }
#    }
#    @combined{keys %combined} = @len_hash{keys %combined};
#
#    return \%combined;
#}

sub pp_assign {
    my $paths = shift;

    my %combined;

    foreach my $path (values %$paths) {
        Biodiverse::Utils::PP::add_hash_keys_lastif (\%combined, $path);
    }

    Biodiverse::Utils::PP::copy_values_from (\%combined, \%len_hash);

    return \%combined;
}

sub xs_assign {
    my $paths = shift;

    my %combined;

    foreach my $path (values %$paths) {
        Biodiverse::Utils::XS::add_hash_keys_lastif (\%combined, $path);
    }

    Biodiverse::Utils::XS::copy_values_from (\%combined, \%len_hash);

    return \%combined;
}

