use Test::More;
use Test::Most;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

my @expected = (
    {n => 161, p => 161 - 13, m => 103, exp => 6.61749303683324e-007},
    {n => 161, p => 161 - 1,  m => 103, exp => 0.360248447204969},
    {n => 161, p => 161 - 7,  m => 103, exp => 0.000616837147145439},
    {n => 509, p => 508,      m => 79,  exp => 0.844793713163065},
    {n => 509, p => 509 - 10, m => 79,  exp => 0.182119049059099},
    {n => 509, p => 509 - 13, m => 79,  exp => 0.108469763182597},
);

my $tol = 1e-14;
foreach my $set (@expected) {
    my ($n, $p, $m, $exp) = @$set{qw /n p m exp/};
    my $pp = Biodiverse::Utils::PP::get_bnok_ratio ($n, $m, $p);
    my $xs = Biodiverse::Utils::XS::get_bnok_ratio ($n, $m, $p);
    ok (abs ($exp - $pp) < $tol, "pp for $n, $p, $m, $p is $exp");
    #diag $pp;
    ok (abs ($exp - $xs) < $tol, "xs for $n, $m, $p");
    #diag $xs;
}


my @croakers = (
    {n => -1,  p => -13, m => -103},
    {n => -10, p =>  13, m =>    3},
    {n =>  10, p =>  13, m =>  103},
    {n =>  10, p =>   1, m =>    3},
);

foreach my $set (@croakers) {
    my ($n, $p, $m, $exp) = @$set{qw /n p m exp/};
    my $text = "croak n=$n,m=$m,p=$p";
    dies_ok {Biodiverse::Utils::PP::get_bnok_ratio ($n, $m, $p)} "pp $text";
    dies_ok {Biodiverse::Utils::XS::get_bnok_ratio ($n, $m, $p)} "xs $text";
}


done_testing();

