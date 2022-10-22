use 5.026;
use strict;
use warnings;


use Benchmark qw {:all};

use Test2::V0;

use Data::Printer;

#use rlib;
use blib;
use PDL::PDLness;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

use Math::Random::MT::Auto;

my $prng4 = Math::Random::MT::Auto->new(seed => 4222);

use List::Util qw /max/;

$| = 1;
my $run_comp = -3;

my @node_counts = (10, 100, 500, 1000);
@node_counts = (50000);
my $starter = 'a';
my @names = map {++$starter} (0 .. max (@node_counts)+20);
#say join ' ', @names;

foreach my $node_count (@node_counts) {
    print "\nCount is $node_count\n";

    #  grow a bifurcating tree
    my ($paths, $node_num_hash) = generate_paths ($node_count);

    my $max = List::Util::max(values %$node_num_hash);
    ($_ = $max - $_) for values %$node_num_hash;
    my $node_num_hash_by_idx = {reverse %$node_num_hash};
    #p $node_num_hash;

    my $key_lists = $prng4->shuffle ($paths);
    #  knock out 10%
    shift @$key_lists for (0 .. int (0.3 * @$key_lists));
    say sprintf "Operating on %d paths", scalar @$key_lists;
    my $len_sum;
    $len_sum += @$_ for @$key_lists;
    say sprintf ("Average path length: %f", $len_sum / scalar @$key_lists);
    #$key_lists = [@$key_lists[0..2]];
    #p $key_lists;

    my $hash_crash = hash_crash ($key_lists);
    my $last_if    = last_if ($key_lists);
    my $xs         = xs ($key_lists);
    my $pp         = pp ($key_lists);
    my $pdl_loop   = pdl_loop($key_lists, $node_num_hash, $node_num_hash_by_idx);

    is ($xs, $pdl_loop,   "xs and pdl_loop match");
    is ($xs, $last_if,    "xs and next_if match");
    is ($xs, $hash_crash, "xs and hash_crash match");
    is ($xs, $pp,         "xs and pp match");

    #printf "%12s%8d\n", "hash_crash:", scalar keys %$hash_crash;
    #printf "%12s%8d\n", "last_if:", scalar keys %$hash_crash;
    #printf "%12s%8d\n", "pp:", scalar keys %$pp;
    #printf "%12s%8d\n", "xs:", scalar keys %$xs;

    if ($run_comp) {
        cmpthese (
            $run_comp,
            {
                hash_crash => sub {hash_crash($key_lists)},
                last_if    => sub {last_if($key_lists)},
                xs         => sub {xs($key_lists)},
                pp         => sub {pp($key_lists)},
                pdl_loop   => sub {pdl_loop ($key_lists, $node_num_hash, $node_num_hash_by_idx)},
            }
        );
    }
}

done_testing();

sub generate_paths {
    my $n = shift // 2000;

    my %tree;
    my %node_num_hash = (
        $names[1] => 1,
        $names[0] => 0,
    );
    my %parent_hash = ($names[1] => $names[0]);
    my @children = (1);
    while (defined (my $i = shift @children)) {
        my @current = ($i * 2, $i * 2 + 1);
        push @children, @current;
        $parent_hash{$names[$current[0]]} = $names[$i];
        $parent_hash{$names[$current[1]]} = $names[$i];
        $tree{$names[$i]} = [@names[@current]];
        $tree{$names[$current[0]]} = [];
        $tree{$names[$current[1]]} = [];
        @node_num_hash{$names[$current[0]], $names[$current[1]]} = @current;
        #say join ' ', @current;
        last if keys %parent_hash >= $n;
    }
    
    say 'Tree generated';
    
    use Data::Printer;
    #p %tree;
    #p %parent_hash;
    my @terminals = sort grep {scalar @{$tree{$_}} == 0} keys %tree;
    #p @terminals;
    
    my @paths_to_root;
    foreach my $terminal (@terminals) {
        my @path = ($terminal);
        my $parent = $parent_hash{$terminal};
        while ($parent) {
           push @path, $parent;
           $parent = $parent_hash{$parent};
        }
        push @paths_to_root, \@path;
    }
    #p @paths_to_root;
    say "Generated " . scalar @paths_to_root . " paths";

    return (\@paths_to_root, \%node_num_hash);
}


sub xs {
    my $key_lists = shift;
    
    my %path;
    #@path{@{$key_lists->[0]}} = ();

    for my $sub_list (@$key_lists) {
        Biodiverse::Utils::XS::add_hash_keys_until_exists (\%path, $sub_list);
    }
    
    return \%path;
}

sub pp {
    my $key_lists = shift;
    
    my %path;

    for my $sub_list (@$key_lists) {
        Biodiverse::Utils::PP::add_hash_keys_until_exists (\%path, $sub_list);
    }
    
    return \%path;
}

sub hash_crash {
    my $key_lists = shift;
    
    my %path;

    for my $sub_list (@$key_lists) {
        @path{@$sub_list} = ();
    }
    
    return \%path;
}

sub last_if {
    my $key_lists = shift;

    my %path;

    for my $sub_list (@$key_lists) {
        for my $label (@$sub_list) {
            last if exists $path{$label};
            $path{$label} = undef;
        }
    }
    
    return \%path;
}


sub pdl_loop {
    my ($key_lists, $node_num_hash, $node_num_hash_by_idx) = @_;

    use PDL::Lite;
    use PDL::Core qw(pdl zeroes);
    use PDL::NiceSlice;

    my $boolean = PDL->zeroes(PDL::byte(), scalar keys %$node_num_hash);
    say $boolean if !$run_comp;
    
    state %cache;
    
    #p $node_num_hash;
    
    foreach my $path (@$key_lists) {
        my $index_pdl = $cache{$path->[0]} //= PDL::indx([@$node_num_hash{@$path}]);
        PDL::PDLness::loopdeloop ($index_pdl, $boolean);
        #$boolean($index_pdl) .= 1 
    }
    say $boolean if !$run_comp;
    my $which = PDL::which ($boolean);
    say $which if !$run_comp;
    (say join ' ', @{$which->unpdl}) if !$run_comp;
    my %path;
    @path{@$node_num_hash_by_idx{@{$which->unpdl}}} = ();
    (say join ' ', reverse sort keys %path) if !$run_comp;
    return \%path;
}



1;


