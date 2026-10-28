# Fingerprint the normalizer

A hash over everything a caller may legitimately **precompute and
cache**: the rule tables and functions behind
[`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md),
the corpus statistics
([`np_name_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_freq.md),
[`np_token_idf()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_token_idf.md),
[`np_stopwords()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_stopwords.md)),
and the tokenizer behind
[`npmatch::np_ref_index()`](https://nonprofit-open-data-collective.github.io/npmatch/reference/np_ref_index.html).

## Usage

``` r
np_normalize_signature(detail = FALSE)
```

## Arguments

- detail:

  If `TRUE`, also return the per-component hashes, so a mismatch can be
  localized to the rule table or function that moved. Default `FALSE`.

## Value

A signature string such as `"v1-a1b2c3d4e5f60718"`. With
`detail = TRUE`, an `np_signature` object carrying that string, the
per-component hashes, and the npnormalize version.

## Why

A cached reference stores derived columns — `name_key`, `street_key`,
`zip9` — while the query side is normalized at run time by whatever
npnormalize is installed. Change the normalizer between those two
moments and the sides are normalized differently: matches quietly stop
being found, with no error and a symptom that reads as a data problem.
Stamp this value into an artifact when you build it, compare on load,
and **error** on mismatch.

## What is covered

Only what is precomputable. Comparison, scoring, vetoes, selection and
tiering are excluded by design — none of them is cached, so a change
there must not invalidate an artifact. A signature that fires on
unrelated edits is one people learn to ignore.

Function bodies are compared after
[`utils::removeSource()`](https://rdrr.io/r/utils/removeSource.html), so
**comments and reformatting leave the signature unchanged while logic
changes move it**.

## Stability

The returned string carries a `v1-` format prefix. If a later
npnormalize changes *what* is hashed, the prefix changes too, so that is
distinguishable from a change to the normalizer itself.

## See also

[`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md)

## Examples

``` r
sig <- np_normalize_signature()
sig
#> [1] "v1-3e7b9f9d59bbb19e"

# which components make it up
names(np_normalize_signature(detail = TRUE)$components)
#>  [1] ".np_abbrev"             ".np_addr_class"         ".np_addr_key"          
#>  [4] ".np_basic_clean"        ".np_canon_form"         ".np_clean_name"        
#>  [7] ".np_core_stop"          ".np_directions"         ".np_doc_freq"          
#> [10] ".np_extract_direction"  ".np_extract_form"       ".np_extract_generation"
#> [13] ".np_extract_numbers"    ".np_extract_ordinals"   ".np_extract_unit"      
#> [16] ".np_gen_rank"           ".np_generation"         ".np_is_placeholder"    
#> [19] ".np_is_pobox"           ".np_legal_suffixes"     ".np_map_special"       
#> [22] ".np_name_core"          ".np_norm_unit"          ".np_ordinals"          
#> [25] ".np_parse_street"       ".np_parse_zip"          ".np_placeholder_re"    
#> [28] ".np_placeholder_tok"    ".np_pobox_pat"          ".np_replace_tokens"    
#> [31] ".np_special_letters"    ".np_state_abbr"         ".np_state_codes"       
#> [34] ".np_street_key"         ".np_street_type_set"    ".np_street_types"      
#> [37] ".np_strip_joiners"      ".np_strip_lead_the"     ".np_strip_suffix"      
#> [40] ".np_to_state_abb"       ".np_tokenize"           ".np_tokens"            
#> [43] ".np_unit_designators"   ".np_unit_id"            ".np_unit_pat"          
#> [46] "np_addr_freq"           "np_name_core"           "np_name_freq"          
#> [49] "np_name_placeholder"    "np_normalize"           "np_stopwords"          
#> [52] "np_token_idf"          
```
