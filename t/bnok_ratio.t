use Test::More;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

my @expected = (
    {n => 161, p => 161 - 13, m => 103, exp => 6.61749303683324e-007},
    {n => 161, p => 161 - 1,  m => 103, exp => 0.360248447204969},
    {n => 161, p => 161 - 7,  m => 103, exp => 0.000616837147145439},
);

my $tol = 1e-14;
foreach my $set (@expected) {
    my ($n, $p, $m, $exp) = @$set{qw /n p m exp/};
    my $pp = Biodiverse::Utils::PP::get_bnok_ratio ($n, $m, $p);
    #my $xs = Biodiverse::Utils::XS::get_bnok_ratio ($n, $m, $p);
    ok (abs ($exp - $pp) < $tol, "pp for $n, $p, $m, $p is $exp");
    #diag $pp;
    #ok (abs ($exp - $xs) < $tol, "xs for $n, $m, $p");
}


done_testing();

