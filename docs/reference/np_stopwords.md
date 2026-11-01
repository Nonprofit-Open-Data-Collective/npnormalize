<div id="main" class="col-md-9" role="main">

# Blocking stopwords

<div class="ref-description section level2">

Non-discriminating legal/filler tokens dropped from name-token blocking
so blocks stay small and precise. Deliberately conservative (legal forms
and function words only) — rely on `max_ref_freq` in
`npmatch::np_block()` to prune the remaining corpus-common words
data-drivenly rather than hard-coding them.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_stopwords()
```

</div>

</div>

<div class="section level2">

## Value

A character vector of uppercase stopwords.

</div>

</div>
