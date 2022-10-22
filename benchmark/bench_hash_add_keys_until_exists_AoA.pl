use strict;
use warnings;

use Benchmark qw {:all};
use 5.016;

use List::Util qw /max/;

#use Panda::Lib qw /hash_merge/;  #  does not work on windows
use Test2::V0;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

use Data::Printer;

use Math::Random::MT::Auto;

my $prng4 = Math::Random::MT::Auto->new(seed => 222);

our @reps = reverse (0 .. 1000);
#say STDERR join ' ', @reps;


$| = 1;

my @labels = (1 .. 10000);
my $max = $labels[-1];

my $check_count = 100;

my @node_counts = (10, 100, 500, 1000);
@node_counts = (5000);
my $starter = 'a';
my @names = map {++$starter} (0 .. max (@node_counts)+20);

foreach my $node_count (@node_counts) {
    print "\nCount is $node_count\n";

    #  grow a bifurcating tree
    my ($paths, $node_num_hash) = generate_paths ($node_count);

    my @key_lists = @$paths;
#p @key_lists;

    #my $hash_crash = hash_crash (\@key_lists);
    my $last_if    = last_if (\@key_lists);
    my $xs         = xs (\@key_lists);
    my $pp         = pp (\@key_lists);
    my $xs_aoa     = xs_aoa (\@key_lists);
    my $xs_aoa_kv_assgn = xs_aoa_kv_assgn (\@key_lists, $node_num_hash);
    my $xs_aoa_and_assgn = xs_aoa_and_assgn (\@key_lists, $node_num_hash);

    is ([sort keys %$xs], [sort keys %$xs_aoa_kv_assgn], "keys match for xs kv assgn");
    is ([sort keys %$xs], [sort keys %$xs_aoa_and_assgn], "keys match for xs and assgn");
    is ($xs, $xs_aoa, "xs and xs_aoa match");
    is ($xs, $last_if, "xs and next_if match");
    #is ($xs, $hash_crash, "xs and hash_crash match");
    is ($xs, $pp, "xs and pp match");

    #printf "%12s%8d\n", "hash_crash:", scalar keys %$hash_crash;
    #printf "%12s%8d\n", "last_if:", scalar keys %$hash_crash;
    #printf "%12s%8d\n", "pp:", scalar keys %$pp;
    #printf "%12s%8d\n", "xs:", scalar keys %$xs;

    if (1) {
        cmpthese (
            10,
            {
                #hash_crash => sub {hash_crash(\@key_lists)},
                last_if    => sub {last_if(\@key_lists)},
                xs         => sub {xs(\@key_lists)},
                xs_aoa     => sub {xs_aoa(\@key_lists)},
                xs_aoa_and_assgn => sub {xs_aoa_and_assgn(\@key_lists, $node_num_hash)},
                xs_aoa_kv_assgn  => sub {xs_aoa_kv_assgn(\@key_lists, $node_num_hash)},
                #pp         => sub {pp(\@key_lists)},
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
    for my $i (@reps) {
        my $p = {};
   
        for my $sub_list (@$key_lists) {
            Biodiverse::Utils::XS::add_hash_keys_until_exists ($p, $sub_list);
        }
       
        if (!$i) {
            %path = %$p;
        }
    }
    
    return \%path;
}

sub xs_aoa {
    my $key_lists = shift;
    
    my %path;
    for my $i (@reps) {
        my $p = {};

        Biodiverse::Utils::XS::add_hash_keys_until_exists_AoA ($p, $key_lists);
        
        if (!$i) {
            %path = %$p;
        }
    }

    return \%path;
}

sub xs_aoa_and_assgn {
    my ($key_lists, $val_hash) = @_;
    
    my %path;
    for my $i (@reps) {
        my $p = {};

        Biodiverse::Utils::XS::add_hash_keys_until_exists_AoA ($p, $key_lists);
        Biodiverse::Utils::XS::copy_values_from ($p, $val_hash);
        
        if (!$i) {
            %path = %$p;
        }
    }

    return \%path;
}

sub xs_aoa_kv_assgn {
    my ($key_lists, $val_hash) = @_;
    
    my %path;
    for my $i (@reps) {
        my $p = {};

        Biodiverse::Utils::XS::add_hash_keys_and_vals_until_exists_AoA ($p, $key_lists, $val_hash);
        
        if (!$i) {
            %path = %$p;
        }
    }

    return \%path;
}

sub pp {
    my $key_lists = shift;
    
    my %path;

    for my $i (@reps) {
        my $p = {};

        for my $sub_list (@$key_lists) {
            Biodiverse::Utils::PP::add_hash_keys_until_exists ($p, $sub_list);
        }
        
        if (!$i) {
            %path = %$p;
        }
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
    for my $i (@reps) {
        my $p = {};

        for my $sub_list (@$key_lists) {
            for my $label (@$sub_list) {
                last if exists $p->{$label};
                $p->{$label} = undef;
            }
        }
        
        if (!$i) {
            %path = %$p;
        }
    }
    
    return \%path;
}


