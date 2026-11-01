<div id="main" class="col-md-9" role="main">

# Name-normalization rule tables

<div class="ref-description section level2">

The tables `np_normalize()` uses, for packages that need the same rules
in another engine (for example a DuckDB SQL macro). A port should be
checked against `np_name_core()` on test strings; the tables are covered
by `np_normalize_signature()`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_name_rules()
```

</div>

</div>

<div class="section level2">

## Value

A list: `abbrev` (named character, token to expansion), `core_stop`
(tokens dropped from `name_core`), `legal_suffixes` (trailing tokens
stripped from `name_key`), `special_letters` (named character, a
non-decomposable Latin letter to its ASCII spelling, folded before
de-accenting), `placeholder_re` (a Perl regex on the raw upper-cased
name) and `placeholder_tok`.

</div>

</div>
