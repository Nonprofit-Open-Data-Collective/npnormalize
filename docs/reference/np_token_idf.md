<div id="main" class="col-md-9" role="main">

# Per-token inverse document frequency for a reference corpus

<div class="ref-description section level2">

Document frequency of each name token across the reference, turned into
`idf = log(N / df)`: rare tokens (distinctive, high IDF) are the ones
the name-token blocking leverages; corpus-common tokens (low IDF) are
not. Feed the result to `npmatch::np_route()` (`token_idf =`) to
annotate the tokenized name fields with each token's rarity, exposing
which tokens carry the match.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_token_idf(name_keys, stopwords = np_stopwords(), min_token_len = 2L)
```

</div>

</div>

<div class="section level2">

## Arguments

-   name_keys:

    Character vector of normalized names (reference `name_key`).

-   stopwords:

    Tokens to drop (see `np_stopwords()`).

-   min_token_len:

    Minimum token length to count. Default 2.

</div>

<div class="section level2">

## Value

A named numeric vector mapping token -> IDF.

</div>

</div>
