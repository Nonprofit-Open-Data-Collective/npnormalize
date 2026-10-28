# npnormalize: nonprofit names and addresses as matchable keys

The normalizer shared by npmatch, matchdb and the packages built on
them.
[`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md)
turns an organization's name and address into keys (`name_key`,
`name_core`, `street_key`, the ZIP parts and more), and
[`np_name_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_freq.md),
[`np_token_idf()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_token_idf.md)
and
[`np_addr_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_addr_freq.md)
count statistics over those keys.

## Details

A record and the reference it is matched against have to be normalized
by the same code, or matches quietly stop being found.
[`np_normalize_signature()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize_signature.md)
is a hash of that code. matchdb stamps it into everything it publishes,
and refuses to use a stored artifact under a different normalizer.

This code was moved out of npmatch unchanged (`dev/EXTRACTION.md`), so
the signature it gives is the one npmatch gave.

## See also

Useful links:

- <https://github.com/Nonprofit-Open-Data-Collective/npnormalize>

- <https://nonprofit-open-data-collective.github.io/npnormalize/>

- Report bugs at
  <https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues>

## Author

**Maintainer**: Jesse Lecy <jdlecy@gmail.com>
