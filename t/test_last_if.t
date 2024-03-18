use Test::More;
use strict;
use warnings;


use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

use List::Util qw /max/;

local $| = 1;

my $n = 20;   #  depth of the paths
my $m = 1800;  #  number of paths
#$m = 500;
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
    my $same_to = max (1, int (rand()*$r));
    my @a;
    @a = map {$_ => $_} (0 .. $same_to);
    push @a, map {((1+$m)*$i*$n+$_) => $_} ($same_to+1 .. $n);
    my %hash = @a;
    $path_hashes{$i} = \%hash;
    $path_arrays{$i} = [reverse sort {$a <=> $b} keys %hash];

    @len_hash{keys %hash} = values %hash;
}
my %all_path_keys;
foreach my $path (values %path_arrays) {
    @all_path_keys{@$path} = ();
}
my @all_path_key_arr = sort {$a <=> $b} keys %all_path_keys;


#  only really need to test pp_assign and xs_assign - the rest is useful paranoia
my $sliced = slice (\%path_hashes);
my $forled = pp_assign (\%path_arrays);
my $slice2 = slice_mk2 (\%path_hashes);
my $inline = xs_assign (\%path_arrays);

is_deeply ($sliced, \%len_hash, 'slice results are the same');
is_deeply ($slice2, \%len_hash, 'slice2 results are the same');
is_deeply ($forled, \%len_hash, 'forled results are the same');
is_deeply ($inline, \%len_hash, 'inline results are the same');

#  now the Array of Arrays
my $inline_AoA = xs_assign_AoA (\%path_arrays);
is_deeply ($inline_AoA, \%len_hash, 'inline results are the same');

use Data::Printer;
#p $inline_AoA;
#p $inline;

#  now the AoA variant that also assigns values
#diag "--- " . keys %len_hash;
my $inline_AoA_v = xs_assign_AoA_vals (\%path_arrays, \%len_hash);
is_deeply ($inline_AoA_v, \%len_hash, 'inline kv assign results are the same');

my %len_hash_undef_vals;
@len_hash_undef_vals{keys %len_hash} = ();
$inline_AoA_v = xs_assign_AoA_vals (\%path_arrays, {});
is_deeply ($inline_AoA_v, \%len_hash_undef_vals, 'inline kv assign results are the same, empty from_hash');

{
    my @keys_to_delete = @all_path_key_arr[0..10];
    #diag join ' ', @keys_to_delete;
    delete local @len_hash{@keys_to_delete};  #  remove some keys
    $inline_AoA_v = xs_assign_AoA_vals (\%path_arrays, \%len_hash);
    @len_hash{@keys_to_delete} = ();  #  now assign undef
    is_deeply ($inline_AoA_v, \%len_hash, 'inline kv assign results are the same, missing keys');
}

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
        Biodiverse::Utils::PP::add_hash_keys_until_exists (\%combined, $path);
    }

    Biodiverse::Utils::PP::copy_values_from (\%combined, \%len_hash);

    return \%combined;
}

sub xs_assign {
    my $paths = shift;

    my %combined;

    foreach my $path (values %$paths) {
        Biodiverse::Utils::XS::add_hash_keys_until_exists (\%combined, $path);
    }

    Biodiverse::Utils::XS::copy_values_from (\%combined, \%len_hash);

    return \%combined;
}

sub xs_assign_AoA {
    my $paths = shift;

    my %combined;
    my $aref = [@$paths{sort keys %$paths}];  #  sorted to be reproducible
#p $aref;
    Biodiverse::Utils::XS::add_hash_keys_until_exists_AoA (\%combined, $aref);
#say STDERR join ' ', sort keys %combined;
    Biodiverse::Utils::XS::copy_values_from (\%combined, \%len_hash);
#say STDERR join ' ', sort keys %combined;
#say STDERR "DONE";
    return \%combined;
}

sub xs_assign_AoA_vals {
    my ($paths, $len_hash) = @_;

    my %combined;
    my $aref = [@$paths{sort keys %$paths}];  #  sorted to be repro {}ducible
#p $aref;
#diag "About to run";
#my $nk = @{$aref->[0]};
#diag "There are $nk keys in first array";
    Biodiverse::Utils::XS::add_hash_keys_and_vals_until_exists_AoA (\%combined, $aref, $len_hash);
#diag join ' ', sort keys %combined;
#say STDERR "DONE";
    return \%combined;
}

#  more thorough testing of the xsub
sub xs_assign_AoA_vals_empty_hash {
    my ($paths, $len_hash) = @_;

    my %combined;
    my $aref = [@$paths{sort keys %$paths}];  #  sorted to be reproducible
    Biodiverse::Utils::XS::add_hash_keys_and_vals_until_exists_AoA (\%combined, $aref, {});
    
    return \%combined;
}