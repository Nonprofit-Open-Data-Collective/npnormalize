# Internals npmatch and matchdb call

Thin, exported wrappers around five internal helpers. npmatch's
blocking, comparison and geography code, and matchdb's place keys, call
these instead of reaching into this package's internals. Most users
never call them.

## Usage

``` r
np_tokenize(frame, token_col, stopwords, min_token_len, concat_adjacent)

np_doc_freq(row, token)

np_addr_key(street_keys, zip5 = NULL)

np_unit_id(unit)

np_state_abb(state)
```

## Arguments

- frame:

  A data frame holding `token_col`.

- token_col:

  The column to tokenize.

- stopwords:

  Tokens to drop (see
  [`np_stopwords()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_stopwords.md)).

- min_token_len:

  Shortest token kept.

- concat_adjacent:

  Also index adjacent-token concatenations.

- row, token:

  Parallel vectors: the row each token came from, and the token.

- street_keys, zip5:

  Street keys and ZIP codes from
  [`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md).

- unit:

  Suites as
  [`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md)
  writes them in `street_unit` (`"STE 300"`, `"FL 2"`, `"# 12"`).

- state:

  State names or codes.

## Value

`np_tokenize()`: a list of base and concatenated token tables.
`np_doc_freq()`: a named numeric vector of row counts per token.
`np_addr_key()`: a character vector of address keys. `np_unit_id()`: a
character vector of suite identifiers, `NA` where there is none.
`np_state_abb()`: a character vector of two-letter codes, `NA` where
none applies.

## Details

- `np_tokenize()` splits a column into tokens for the blocking index, as
  [`npmatch::np_ref_index()`](https://nonprofit-open-data-collective.github.io/npmatch/reference/np_ref_index.html)
  and
  [`npmatch::np_block()`](https://nonprofit-open-data-collective.github.io/npmatch/reference/np_block.html)
  do.

- `np_doc_freq()` counts, for each token, the rows it appears in.

- `np_addr_key()` builds the address key
  [`np_addr_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_addr_freq.md)
  counts on: the street key and ZIP, blank for a PO box.

- `np_unit_id()` reduces a suite as written to its identifier: the
  designator and separators are dropped, so `"STE 300"`, `"Suite 300"`
  and `"# 300"` all give `"300"`, and `"STE D-2"` gives `"D2"`. This is
  the `street_unit_id` column
  [`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md)
  adds, computed from `street_unit`.

- `np_state_abb()` maps a state name or code to its two-letter code.

They are not part of the normalizer signature: each calls a function
that is
([`np_normalize_signature()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize_signature.md)),
and adds nothing of its own.
