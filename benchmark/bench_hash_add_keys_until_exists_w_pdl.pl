
use Benchmark qw {:all};
use 5.016;

#use Panda::Lib qw /hash_merge/;  #  does not work on windows
use Test2::V0;

use Data::Printer;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

use Math::Random::MT::Auto;

my $prng4 = Math::Random::MT::Auto->new(seed => 222);


$| = 1;

#  grow a bifurcating tree
my @names = 'a' .. 'zzzzz';

my @node_counts = (10, 100, 500, 1000);
@node_counts = (100);

foreach my $node_count (@node_counts) {
    print "\nCount is $node_count\n";

    my $paths = generate_paths ($node_count);

    my @key_lists = $prng4->shuffle ($paths);
    p @key_lists;

    my $hash_crash = hash_crash (\@key_lists);
    my $last_if    = last_if (\@key_lists);
    my $xs         = xs (\@key_lists);
    my $pp         = pp (\@key_lists);

    is ($xs, $last_if, "xs and next_if match");
    is ($xs, $hash_crash, "xs and hash_crash match");
    is ($xs, $pp, "xs and pp match");

    #printf "%12s%8d\n", "hash_crash:", scalar keys %$hash_crash;
    #printf "%12s%8d\n", "last_if:", scalar keys %$hash_crash;
    #printf "%12s%8d\n", "pp:", scalar keys %$pp;
    #printf "%12s%8d\n", "xs:", scalar keys %$xs;

    cmpthese (
        -3,
        {
            hash_crash => sub {hash_crash(\@key_lists)},
            last_if    => sub {last_if(\@key_lists)},
            xs         => sub {xs(\@key_lists)},
            pp         => sub {pp(\@key_lists)},
        }
    );
}

done_testing();

sub generate_paths {
    my $n = shift // 2000;

    my %tree;
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

    return (\@paths_to_root);
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


__END__

perl 5.20.0, centos linux box

perl bench_hash_merger_panda.pl

Check count is 10
ok 1 - panda and grep_first match
ok 2 - panda and next_if match
ok 3 - panda and hash_crash match
      panda:    1001
 grep_first:    1001
 hash_crash:    1001
    next_if:    1001
             Rate    next_if grep_first hash_crash      panda
next_if    2574/s         --        -6%       -31%       -59%
grep_first 2749/s         7%         --       -27%       -56%
hash_crash 3751/s        46%        36%         --       -40%
panda      6208/s       141%       126%        65%         --

Check count is 50
ok 4 - panda and grep_first match
ok 5 - panda and next_if match
ok 6 - panda and hash_crash match
      panda:    1041
 grep_first:    1041
 hash_crash:    1041
    next_if:    1041
             Rate    next_if grep_first hash_crash      panda
next_if     797/s         --       -16%       -34%       -59%
grep_first  954/s        20%         --       -21%       -51%
hash_crash 1206/s        51%        26%         --       -38%
panda      1934/s       143%       103%        60%         --

Check count is 100
ok 7 - panda and grep_first match
ok 8 - panda and next_if match
ok 9 - panda and hash_crash match
      panda:    1091
 grep_first:    1091
 hash_crash:    1091
    next_if:    1091
             Rate    next_if grep_first hash_crash      panda
next_if     439/s         --       -18%       -34%       -60%
grep_first  534/s        22%         --       -20%       -51%
hash_crash  666/s        52%        25%         --       -39%
panda      1101/s       150%       106%        65%         --

Check count is 300
ok 10 - panda and grep_first match
ok 11 - panda and next_if match
ok 12 - panda and hash_crash match
      panda:    1291
 grep_first:    1291
 hash_crash:    1291
    next_if:    1291
            Rate    next_if grep_first hash_crash      panda
next_if    155/s         --       -21%       -35%       -61%
grep_first 195/s        26%         --       -18%       -51%
hash_crash 238/s        53%        22%         --       -41%
panda      402/s       159%       106%        69%         --

Check count is 500
ok 13 - panda and grep_first match
ok 14 - panda and next_if match
ok 15 - panda and hash_crash match
      panda:    1491
 grep_first:    1491
 hash_crash:    1491
    next_if:    1491
             Rate    next_if grep_first hash_crash      panda
next_if    94.4/s         --       -20%       -34%       -62%
grep_first  118/s        25%         --       -18%       -52%
hash_crash  143/s        51%        22%         --       -42%
panda       246/s       160%       109%        72%         --

Check count is 1000
ok 16 - panda and grep_first match
ok 17 - panda and next_if match
ok 18 - panda and hash_crash match
      panda:    1991
 grep_first:    1991
 hash_crash:    1991
    next_if:    1991
             Rate    next_if grep_first hash_crash      panda
next_if    44.9/s         --       -18%       -31%       -59%
grep_first 55.0/s        23%         --       -16%       -49%
hash_crash 65.5/s        46%        19%         --       -40%
panda       109/s       142%        98%        66%         --
