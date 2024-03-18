package Biodiverse::Utils;

use strict;
use warnings;

our $VERSION = '1.10';

BEGIN {
    eval 'use Biodiverse::Utils::XS qw /:all/;';
    if ($@) {
        'use Biodiverse::Utils::PP qw /:all/';
    }
}

use Exporter 'import';
our @EXPORT_OK = qw(
    add_hash_keys
    add_hash_keys_until_exists
    copy_values_from
    get_rpe_null
    get_hash_shared_and_unique
    get_bnok_ratio
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

1;


__END__


=head1 NAME

Biodiverse::Utils - Utilities for the Biodiverse software.

=head1 SYNOPSIS

  use Biodiverse::Utils qw /:all/;

  my $dest_hash_ref = {}
  my $from_hash_ref = {a => 1, b => 2, c => 3};
  my @extra_keys = qw /f e d c b a/;

  add_hash_keys ($dest_hash_ref, $from_hash_ref)
  print join ' ', sort keys %$dest_hash_ref;
  #  a b c
  add_hash_keys_until_exists ($dest_hash_ref, \@extra_keys)
  print join ' ', sort keys %$dest_hash_ref;
  #  a b c d e f
  
  my %h1 = (xa => 1, xb => 2);
  my %h2 = (xa => 3, xc => 2);
  get_hash_shared_and_unique (\%h1, %h2)
  #  {a => {xa => 1}, b => {xb => 2}, c => {xc => 2}}

=head1 ABSTRACT

Provides a set of utility functions 
in the Biodiverse software (L<http://purl.org/biodiverse>).
These are in both XS (using Inline::Module) and pure perl.
The XS is used by default.  If you want the pure perl versions
(and associated performance bottlenecks) then use Biodiverse::Utils::PP.

=head1 DESCRIPTION

These utility functions have been identified as bottlenecks in Biodiverse.
They are not written to be generic, so are likely to
not work as you want except for simple inputs.
Any magic is ignored, as are tied data structures.

There is no doubt also a quantum egregiousness in the XS code.  

Error checking is also very basic, possibly to the point of being highly risky.

Patches are welcome.  

=head1 FUNCTIONS

=over 4

=item add_hash_keys ($dest_hash_ref, $from_hash_ref)

Any keys in C<$from_hash> not already in C<$dest_hash> are
added to C<$dest_hash_ref>.

Values are set to undef, and might in future use the same SV for speed reasons.  

You probably don't want to use this as it is no faster than simply
adding to a hash using a slice, e.g. C<@h1{keys %h2} = undef>.
It is also nowhere near as fast as the L<Panda::Lib> hash_merge function,
but that module fails tests on 64 bit Strawberry Perls
(at version 1.3).

=item add_hash_keys_until_exists ($dest_hash_ref, $from_array_ref)

Adds each item in C<$from_array_ref> as a new key in C<$dest_hash_ref>,
stopping at the first key that exists in $dest_hash_ref.

This is useful for tree data structures when collating branches along a
set of paths from the tips to the root.  Most paths converge somewhere along
the way to the root, so assigning using a slice will repeatedly add
internal branches that are already in $dest_hash from preceding paths.

Note that the value for any new hash keys uses the same SV for each call 
(but not across calls).  This means that, if C<$dest_hash_ref->{a}> and
C<$dest_hash_ref->{b}> are added, then calling C<$dest_hash_ref->{a}++>
will also increment C<$dest_hash_ref->{b}>.  This is done for speed reasons,
and you are best to overwrite the values in a later step using, for example,
C<copy_values_from>.

=item copy_values_from ($dest_hash_ref, $from_hash_ref)

Sets the values in $dest_hash_ref to match those in $from_hash_ref.
Useful in tandem with C<add_hash_keys_until_exists> since new values can be assigned.

One could also use a plain slice, but slicing has more overheads
when used this way.
C<@dest_hash{keys %dest_hash} = @from_hash{keys %dest_hash}>

=item get_rpe_null (\%node_lengths, \%local_ranges, \%global_ranges)

Calculate the null score for the Relative Phylogenetic Endemism index
used in Mishler et al. (2014) L<http://dx.doi.org/10.1038/ncomms5473>.

This is the sum of a set of branch lengths times their local ranges divided by
their global ranges (rpe_null = sum (len * lr / gr)).

The XS version is about twice as fast as the pure perl version.

Searches all keys in %global_ranges, skipping any divide by zero cases.

=item get_hash_shared_and_unique (\%h1, \%h2)

Identifies which keys in two hashes are common, and which are unique to
%h1 and to %h2.

The result is a hashref where the "a" subhash contains the set of common keys,
"b" contains the set of keys unique to %h1,
and "c" contains the set of keys unique to %h2.

The values of the resultant subhashes are the same as the input hashes,
except that values in %h1 will override those in %h2 in the "a" subhash.

This sub could do with a better name.

=item get_bnok_ratio ($n, $m, $p)

Calculate the ratio of two n-choose-k calculations,
avoiding any factorials and the need for bignums along the way.
In Math::BigNum parlance, it is C<< $n->bnok($m) / $p->bnok($m) >>.
The XS version is more than 3000% faster than using Math::BigNum,
and the PP version >450% faster than using Math::BigNum.

=back

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to
  L<https://github.com/shawnlaffan/biodiverse-utils/issues>.

=head1 SEE ALSO

L<http://github.com/shawnlaffan/biodiverse> 
L<Panda::Lib>

=head1 AUTHOR

Shawn Laffan, shawnlaffan@gmail.com


=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Shawn Laffan


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
