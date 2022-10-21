package Biodiverse::Utils::XS;
our $VERSION = '1.07';
use strict; use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    add_hash_keys
    add_hash_keys_until_exists
    add_hash_keys_until_exists_AoA
    copy_values_from
    get_rpe_null
    get_hash_shared_and_unique
    get_bnok_ratio
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

use Biodiverse::Utils::XS::Inline C => <<'...';

void add_hash_keys(SV* dest, SV* from) {
    HV* hash_dest;
    HV* hash_from;
    HE* hash_entry;
    int num_keys_from, num_keys_dest, i;
    SV* sv_key;
    SV* sv_fill_val;

    if (! SvROK(dest))
      croak("dest is not a reference");
    if (! SvROK(from))
      croak("from is not a reference");
 
    hash_from = (HV*)SvRV(from);
    hash_dest = (HV*)SvRV(dest);
    
    num_keys_from = hv_iterinit(hash_from);

    //  Generate one SV and re-use it.
    //  Could use a global SV?
    sv_fill_val = newSV(0);

    for (i = 0; i < num_keys_from; i++) {
        hash_entry = hv_iternext(hash_from);
        sv_key = hv_iterkeysv(hash_entry);
        //  Could use hv_fetch_ent with the lval arg set to 1.
        //  That will autovivify an undef entry
        //  http://stackoverflow.com/questions/19832153/hash-keys-behavior
        if (!hv_exists_ent (hash_dest, sv_key, 0)) {
            // printf ("Did not find key %s\n", SvPV(sv_key, PL_na));
            hv_store_ent(hash_dest, sv_key, SvREFCNT_inc(sv_fill_val), 0);
        }
    }
    SvREFCNT_dec (sv_fill_val);  // avoid mem leak?

    return;
}

void copy_values_from (SV* dest, SV* from) {
    HV* hash_dest;
    HV* hash_from;
    HE* hash_entry_dest;
    HE* hash_entry_from;
    int num_keys_from, num_keys_dest, i;
    SV* sv_key;
    SV* sv_val_from;

    if (! SvROK(dest))
      croak("dest is not a reference");
    if (! SvROK(from))
      croak("from is not a reference");

    hash_from = (HV*)SvRV(from);
    hash_dest = (HV*)SvRV(dest);
  
    // num_keys_from = hv_iterinit(hash_from);
    // printf ("There are %i keys in hash_from\n", num_keys_from);
    num_keys_dest = hv_iterinit(hash_dest);
    // printf ("There are %i keys in hash_dest\n", num_keys_dest);

    for (i = 0; i < num_keys_dest; i++) {
        hash_entry_dest = hv_iternext(hash_dest);  
        sv_key = hv_iterkeysv(hash_entry_dest);
        // printf ("Checking key %i: '%s' (%x)\n", i, SvPV(sv_key, PL_na), sv_key);
        // exists = hv_exists_ent (hash_from, sv_key, 0);
        // printf (exists ? "Exists\n" : "not exists\n");
        if (hv_exists_ent (hash_from, sv_key, 0)) {
            // printf ("Found key %s\n", SvPV(sv_key, PL_na));
            hash_entry_from = hv_fetch_ent (hash_from, sv_key, 0, 0);

            // need to decrement the current ref count before we overwrite it,
            // otherwise Test::LeakTrace notes unhappiness.
            SvREFCNT_dec(HeVAL(hash_entry_dest));
            HeVAL(hash_entry_dest) = newSVsv(HeVAL(hash_entry_from));
        }
    }
    return;
}

// needs a better name
void add_hash_keys_until_exists (SV* dest, SV* from) {
    HV* hash_dest;
    AV* arr_from;
    int i;
    SV* sv_key;
    SV* sv_fill_val;
    int num_keys_from;
 
    if (! SvROK(dest))
      croak("dest is not a reference");
    if (! SvROK(from))
      croak("from is not a reference");

    arr_from  = (AV*)SvRV(from);
    hash_dest = (HV*)SvRV(dest);

    num_keys_from = av_len (arr_from);
    // printf ("There are %i keys in from list\n", num_keys_from+1);

    //  Generate one SV and re-use it.
    //  Need to warn in docs that it is the same SV for all assigned vals,
    //  so change one means change all.
    //  Could use a global SV?
    sv_fill_val = newSV(0);

    //  could use a while loop with condition being the key does not exist in dest?
    for (i = 0; i <= num_keys_from; i++) {
        SV **sv_key = av_fetch(arr_from, i, 0);  //  cargo culted from List::MoreUtils::insert_after
        // printf ("Checking key %s\n", SvPV(*sv_key, PL_na));
        if (hv_exists_ent (hash_dest, *sv_key, 0)) {
          // printf ("Found key %s\n", SvPV(*sv_key, PL_na));
          break;
        }
        //  possible mem leakage?
        hv_store_ent(hash_dest, *sv_key, SvREFCNT_inc(sv_fill_val), 0);
    }
    SvREFCNT_dec (sv_fill_val);  // avoid mem leak?
    return;
}


// also needs a better name
void add_hash_keys_until_exists_AoA (SV* dest, SV* from) {
    HV* hash_dest;
    AV* arr_from;
    int i, j;
    SV* sv_key;
    SV* sv_fill_val;
    int num_keys_from;
    int num_arrays;
    AV* this_arr;
 
    if (! SvROK(dest))
      croak("dest is not a reference");
    if (! SvROK(from))
      croak("from is not a reference");

    arr_from  = (AV*)SvRV(from);
    hash_dest = (HV*)SvRV(dest);

    num_arrays = av_len (arr_from);
    // printf ("There are %i arrays to process\n", num_arrays);

    //  Generate one SV and re-use it.
    //  Need to warn in docs that it is the same SV for all assigned vals,
    //  so change one means change all.
    //  Could use a global SV?
    sv_fill_val = newSV(0);

    for (j = 0; j <= num_arrays; j++) {
        
        SV **this_arr_ref = av_fetch(arr_from, j, 0);
        
        if (SvTYPE(SvRV(*this_arr_ref)) == SVt_PVAV) {
            
            this_arr = (AV*)SvRV(*this_arr_ref);
        
            num_keys_from = av_len (this_arr);
            // printf ("There are %i keys in from list %i\n", num_keys_from+1, j);
        
            //  could use a while loop with condition being the key does not exist in dest?
            for (i = 0; i <= num_keys_from; i++) {
                SV **sv_key = av_fetch(this_arr, i, 0);  //  cargo culted from List::MoreUtils::insert_after
                // printf ("Checking key %s\n", SvPV(*sv_key, PL_na));
                if (hv_exists_ent (hash_dest, *sv_key, 0)) {
                  // printf ("Found key %s\n", SvPV(*sv_key, PL_na));
                  break;
                }
                //  possible mem leakage?
                hv_store_ent(hash_dest, *sv_key, SvREFCNT_inc(sv_fill_val), 0);
            }
        }
    }
    SvREFCNT_dec (sv_fill_val);  // avoid mem leak?
    return;
}

double get_rpe_null (SV* node_lens_ref, SV* local_ranges_ref, SV* global_ranges_ref) {
    HV* node_len_hash;
    HV* local_range_hash;
    HV* global_range_hash;
    HE* he_node_len;
    HE* he_local_range;
    HE* he_global_range;

    SV* sv_key;
    int i, num_keys_from;
    double rpe_null = 0;
    double nl, lr, gr;

    if (! SvROK(node_lens_ref))
      croak("node_lens_ref is not a reference");
    if (! SvROK(local_ranges_ref))
      croak("local_ranges_ref is not a reference");
    if (! SvROK(global_ranges_ref))
      croak("global_ranges_ref is not a reference");
    
    node_len_hash     = (HV*)SvRV(node_lens_ref);
    local_range_hash  = (HV*)SvRV(local_ranges_ref);
    global_range_hash = (HV*)SvRV(global_ranges_ref);

    num_keys_from = hv_iterinit(global_range_hash);
    // printf ("number of hash keys: %i\n", num_keys_from);

    for (i = 0; i < num_keys_from; i++) {
        he_global_range = hv_iternext(global_range_hash);
        sv_key = hv_iterkeysv(he_global_range);
        
        gr = SvNV_nomg (HeVAL(he_global_range));

        he_node_len    = hv_fetch_ent (node_len_hash, sv_key, 0, 0);
        he_local_range = hv_fetch_ent (local_range_hash, sv_key, 0, 0);

        if (he_node_len && he_local_range && gr) {
            nl = SvNV_nomg (HeVAL(he_node_len));
            lr = SvNV_nomg (HeVAL(he_local_range));
            rpe_null += nl * lr / gr;
        }
    }

    return rpe_null;
}


// needs a better name
SV *
get_hash_shared_and_unique (SV* h1, SV* h2) {
    HV* hash_a;
    HV* hash_b;
    HV* hash_c;
    HV* hash1;
    HV* hash2;
    HE* hash_entry;
    HV* result_hash;
    
    hash_a = newHV();
    hash_b = newHV();
    hash_c = newHV();
    result_hash = newHV();

    int i;
    SV* sv_key;
    SV* sv_val;
    int num_keys_h1;
    int num_keys_h2;
 
    if (! SvROK(h1))
      croak("h1 is not a reference");
    if (! SvROK(h2))
      croak("h2 is not a reference");

    hash1 = (HV*)SvRV(h1);
    hash2 = (HV*)SvRV(h2);

    num_keys_h1 = hv_iterinit(hash1);
    num_keys_h2 = hv_iterinit(hash2);

    //  pass over the first hash
    for (i = 0; i < num_keys_h1; i++) {
        hash_entry = hv_iternext(hash1);  
        sv_key = hv_iterkeysv(hash_entry);
        sv_val = newSVsv(HeVAL(hash_entry));

        if (hv_exists_ent (hash2, sv_key, 0)) {
            hv_store_ent(hash_a, sv_key, sv_val, 0);
        }
        else {
            hv_store_ent(hash_b, sv_key, sv_val, 0);
       }
    }

    //  now pass over the second hash
    for (i = 0; i < num_keys_h2; i++) {
        hash_entry = hv_iternext(hash2);  
        sv_key = hv_iterkeysv(hash_entry);
        
        if (!hv_exists_ent (hash1, sv_key, 0)) {
            sv_val = newSVsv(HeVAL(hash_entry));
            hv_store_ent(hash_c, sv_key, sv_val, 0);
        }
    }

    SV* key_a = newSVpvn("a",1);
    SV* key_b = newSVpvn("b",1);
    SV* key_c = newSVpvn("c",1);

    hv_store_ent(result_hash, key_a, (SV*) newRV_noinc((SV *) hash_a), 0);
    hv_store_ent(result_hash, key_b, (SV*) newRV_noinc((SV *) hash_b), 0);
    hv_store_ent(result_hash, key_c, (SV*) newRV_noinc((SV *) hash_c), 0);

    SvREFCNT_dec (key_a);
    SvREFCNT_dec (key_b);
    SvREFCNT_dec (key_c);

    return newRV_noinc((SV *) result_hash);
}

double
get_bnok_ratio (double n, double m, double p) {

    if (m > n || m > p || n <= 0) {
        croak ("invalid args passed to get_bnok_ratio (%i, %i, %i)", m, n, p);
    }

    long nmax, dmax, i;
    double ratio, denom, numer;

    // printf ("Running %i %i %i\n", n, p, m);
    
    numer = p-m+1;
    nmax  = ((n-m) > p) ? n-m : p;
    denom = (n-m > p)   ? p+1 : n-m+1;
    dmax  = n;

    // printf ("numer nmax denom dmax\n%i %i %i %i\n", numer, nmax, denom, dmax);

    
    ratio = 1.0;
    //  divide as we go to avoid numeric overflow
    while ( numer <= nmax && denom <= dmax ) {
        ratio *= numer / denom;
        // printf ("%f ", ratio);
        numer++;
        denom++;
    }
    // printf ("\n");
    //  handle any leftovers
    if (numer <= nmax) {
        for (i = numer; i <= nmax; i++) {
            ratio *= (double) i;
        }
    }
    else if (denom <= nmax) {
        for (i = denom; i <= dmax; i++ ) {
            ratio /= (double) i;
        }
    }

    return (ratio);
}

...

1;
