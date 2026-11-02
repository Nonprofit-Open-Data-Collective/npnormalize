<div id="main" class="col-md-9" role="main">

# Which release produced a normalizer signature

<div class="ref-description section level2">

`np_normalize_signature()` returns an opaque value, which is what makes
it a good fingerprint and a poor label: it says *that* two artifacts
disagree, never which is newer. This dates every signature the package
has published, so a script writing a provenance header can stamp the
release beside the signature instead of a person looking it up in
`NEWS.md`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_signature_history(signature = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   signature:

    Optionally one or more signature strings to look up. A value that is
    not listed returns no rows — it is not an error, and it is not the
    same as a listed row with an `NA` version.

</div>

<div class="section level2">

## Value

A data frame of `signature`, `package`, `version` and `summary`, in
publication order. `version` is the release that *introduced* the
signature; a later release that reports the same value unchanged is
named in `summary` rather than given a row of its own, so one signature
is one row and the column stays usable for comparison.

</div>

<div class="section level2">

## Details

The three oldest rows are npmatch's, from before the normalizer moved
into this package. They are listed so that an unrecognized value can be
told from a recognized pre-split one; their npmatch version was never
recorded, so `version` is `NA` and `summary` says where the value is
cited.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`np_normalize_signature()`

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
np_signature_history(np_normalize_signature())
#>             signature     package version
#> 1 v1-5e901add4a04a5d6 npnormalize   0.1.8
#>                                                                                               summary
#> 1 the join stops closing up a lone compass letter (#16); 0.1.9 reports it too, having changed no rule

# the whole history, oldest first
np_signature_history()[, c("signature", "package", "version")]
#>              signature     package version
#> 1  v1-421e1e2a6afb024e     npmatch    <NA>
#> 2  v1-6dcb298522cc5118     npmatch    <NA>
#> 3  v1-b42811fe6601afe6     npmatch    <NA>
#> 4  v1-3e7b9f9d59bbb19e npnormalize   0.1.0
#> 5  v1-6d90b52d8b781673 npnormalize   0.1.2
#> 6  v1-592912060053c4c3 npnormalize   0.1.3
#> 7  v1-1179714ce1e9d31f npnormalize   0.1.4
#> 8  v1-533f186c123357cf npnormalize   0.1.5
#> 9  v1-d49b18cc81ab79fb npnormalize   0.1.6
#> 10 v1-59c6e84c5f38e9f5 npnormalize   0.1.7
#> 11 v1-5e901add4a04a5d6 npnormalize   0.1.8
```

</div>

</div>

</div>
