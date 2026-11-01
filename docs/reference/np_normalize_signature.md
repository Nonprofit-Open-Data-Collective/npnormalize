<div id="main" class="col-md-9" role="main">

# Fingerprint the normalizer

<div class="ref-description section level2">

A hash over everything a caller may legitimately **precompute and
cache**: the rule tables and functions behind `np_normalize()`, the
corpus statistics (`np_name_freq()`, `np_token_idf()`,
`np_stopwords()`), and the tokenizer behind `npmatch::np_ref_index()`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_normalize_signature(detail = FALSE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   detail:

    If `TRUE`, also return the per-component hashes, so a mismatch can
    be localized to the rule table or function that moved. Default
    `FALSE`.

</div>

<div class="section level2">

## Value

A signature string such as `"v1-a1b2c3d4e5f60718"`. With
`detail = TRUE`, an `np_signature` object carrying that string, the
per-component hashes, and the npnormalize version.

</div>

<div class="section level2">

## Why

A cached reference stores derived columns — `name_key`, `street_key`,
`zip9` — while the query side is normalized at run time by whatever
npnormalize is installed. Change the normalizer between those two
moments and the sides are normalized differently: matches quietly stop
being found, with no error and a symptom that reads as a data problem.
Stamp this value into an artifact when you build it, compare on load,
and **error** on mismatch.

</div>

<div class="section level2">

## What is covered

Only what is precomputable. Comparison, scoring, vetoes, selection and
tiering are excluded by design — none of them is cached, so a change
there must not invalidate an artifact. A signature that fires on
unrelated edits is one people learn to ignore.

Function bodies are compared after `utils::removeSource()`, so
**comments and reformatting leave the signature unchanged while logic
changes move it**.

</div>

<div class="section level2">

## Stability

The returned string carries a `v1-` format prefix. If a later
npnormalize changes *what* is hashed, the prefix changes too, so that is
distinguishable from a change to the normalizer itself.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`np_normalize()`

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
sig <- np_normalize_signature()
sig
#> [1] "v1-1179714ce1e9d31f"

# which components make it up
names(np_normalize_signature(detail = TRUE)$components)
#>  [1] ".np_abbrev"             ".np_addr_class"         ".np_addr_key"          
#>  [4] ".np_basic_clean"        ".np_box_pat"            ".np_canon_form"        
#>  [7] ".np_clean_name"         ".np_core_stop"          ".np_directions"        
#> [10] ".np_doc_freq"           ".np_extract_direction"  ".np_extract_form"      
#> [13] ".np_extract_generation" ".np_extract_numbers"    ".np_extract_ordinals"  
#> [16] ".np_extract_unit"       ".np_gen_rank"           ".np_generation"        
#> [19] ".np_has_box"            ".np_is_placeholder"     ".np_is_pobox"          
#> [22] ".np_legal_suffixes"     ".np_map_special"        ".np_name_core"         
#> [25] ".np_norm_unit"          ".np_ordinals"           ".np_parse_street"      
#> [28] ".np_parse_zip"          ".np_pick_unit"          ".np_placeholder_re"    
#> [31] ".np_placeholder_tok"    ".np_pobox_pat"          ".np_replace_tokens"    
#> [34] ".np_special_letters"    ".np_state_abbr"         ".np_state_codes"       
#> [37] ".np_street_key"         ".np_street_type_set"    ".np_street_types"      
#> [40] ".np_strip_joiners"      ".np_strip_lead_the"     ".np_strip_suffix"      
#> [43] ".np_to_state_abb"       ".np_tokenize"           ".np_tokens"            
#> [46] ".np_unit_designators"   ".np_unit_id"            ".np_unit_pat"          
#> [49] ".np_unit_rank"          "np_addr_freq"           "np_name_core"          
#> [52] "np_name_freq"           "np_name_placeholder"    "np_normalize"          
#> [55] "np_stopwords"           "np_token_idf"          
```

</div>

</div>

</div>
