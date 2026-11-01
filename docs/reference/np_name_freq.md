<div id="main" class="col-md-9" role="main">

# Name-key frequency table for a reference corpus

<div class="ref-description section level2">

Counts how many reference records share each exact `name_key`. A name
that occurs once or twice is distinctive (an exact match to it is
trustworthy even without address corroboration); a name shared by many
records (e.g. "FIRST BAPTIST CHURCH") is not. Used by the
distinctive-exact-name promotion in `np_score(method = "hier")`. This is
more robust than summed token IDF, which conflates distinctiveness with
name length.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_name_freq(name_keys)
```

</div>

</div>

<div class="section level2">

## Arguments

-   name_keys:

    Character vector of normalized names (reference `name_key`).

</div>

<div class="section level2">

## Value

A named integer vector mapping `name_key` -> record count.

</div>

</div>
