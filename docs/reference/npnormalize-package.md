<div id="main" class="col-md-9" role="main">

# npnormalize: nonprofit names and addresses as matchable keys

<div class="ref-description section level2">

The normalizer shared by npmatch, matchdb and the packages built on
them. `np_normalize()` turns an organization's name and address into
keys (`name_key`, `name_core`, `street_key`, the ZIP parts and more),
and `np_name_freq()`, `np_token_idf()` and `np_addr_freq()` count
statistics over those keys.

</div>

<div class="section level2">

## Details

A record and the reference it is matched against have to be normalized
by the same code, or matches quietly stop being found.
`np_normalize_signature()` is a hash of that code. matchdb stamps it
into everything it publishes, and refuses to use a stored artifact under
a different normalizer.

This code was moved out of npmatch unchanged (`dev/EXTRACTION.md`), so
the signature it gives is the one npmatch gave.

</div>

<div class="section level2">

## See also

<div class="dont-index">

Useful links:

-   <https://github.com/Nonprofit-Open-Data-Collective/npnormalize>

-   <https://nonprofit-open-data-collective.github.io/npnormalize/>

-   Report bugs at
    <https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues>

</div>

</div>

<div class="section level2">

## Author

**Maintainer**: Jesse Lecy <jdlecy@gmail.com>

</div>

</div>
