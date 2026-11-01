<div id="main" class="col-md-9" role="main">

# Exact-lookup name key and placeholder check for raw name strings

<div class="ref-description section level2">

`np_name_core()` cleans a name the way `np_normalize()` does (special
letters folded to ASCII, de-accented, upper-cased, `&` to AND,
possessives joined, abbreviations expanded), then drops connector words
and legal forms anywhere in the name (THE, OF, AND, INC, CORP, LLC ...).
Unlike `name_key` it keeps FOUNDATION, TRUST, ASSOCIATION and FUND, so a
charity and its foundation get different keys. Use it for exact lookups
where a key must point to one organisation.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_name_core(x)

np_name_placeholder(x)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    Character vector of names as written.

</div>

<div class="section level2">

## Value

`np_name_core()`: character vector of keys ("" when nothing is left).
`np_name_placeholder()`: logical vector.

</div>

<div class="section level2">

## Details

`np_name_placeholder()` is `TRUE` for names that are not names: blank,
"SEE SCHEDULE O", "N/A", "SAME AS ABOVE", or no letters at all.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
np_name_core(c("The Pueblo Zoological Society", "Pueblo Zoological Society Foundation"))
#> [1] "PUEBLO ZOOLOGICAL SOCIETY"           
#> [2] "PUEBLO ZOOLOGICAL SOCIETY FOUNDATION"
np_name_placeholder(c("SEE SCHEDULE O", "N/A", "Acme Fdn"))
#> [1]  TRUE  TRUE FALSE
```

</div>

</div>

</div>
