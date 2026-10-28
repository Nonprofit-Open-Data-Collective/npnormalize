# Address-sharing statistics for a reference corpus

Counts how many reference records sit at each exact address, at each
address

- suite, and how many distinct suites each address carries. This is what
  makes a suite match *interpretable* rather than merely true:

## Usage

``` r
np_addr_freq(
  street_keys,
  zip5 = NULL,
  unit_ids = NULL,
  name_keys = NULL,
  share_min = 10L,
  unit_coverage_min = 0.5
)
```

## Arguments

- street_keys:

  Normalized street (reference `street_key`).

- zip5:

  Five-digit ZIP, so one street name in two towns is two addresses.

- unit_ids:

  Normalized unit identifiers (reference `street_unit_id`), `NA` where a
  record names no unit.

- name_keys:

  Normalized names (reference `name_key`). Optional, but without them an
  address cannot be classified: the share of records carrying the most
  common name is what separates a federated parent from a fiscal
  sponsor, and counts alone cannot.

- share_min:

  Count above which an address, or an address + suite, counts as
  *shared*. Default 10: below that, repeats are usually variants of one
  organisation — an org, its foundation, its auxiliary — rather than a
  multi-tenant building or a sponsor's mail drop.

- unit_coverage_min:

  Share of the records at an address that must name a suite before
  "several distinct suites here" is read as a fact about the building
  rather than about the data. Default 0.5.

## Value

An `np_addr_freq` list: `addr` (records per address), `addr_unit`
(records per address + suite), `units` (distinct suites per address),
`unit_coverage`, `n_names`, `top_name_share`, `class` (one of
`"federated"`, `"shared"`, `"building"`, `"cluster"`), `share_min` and
`unit_coverage_min`.

## Details

- **One address, many distinct suites** — an office building let to many
  nonprofits, common in cities and often a foundation's building rented
  out to centralize back-office services. Here the suite is the
  differentiator, precisely because an exact-address match surfaces
  every tenant as a candidate.

- **One address + suite shared by many records** — a fiscal sponsor, a
  registered agent, or an accountant's mail drop. The suite is then
  evidence of nothing, and the address is worth flagging to a reviewer
  instead.

Feed the result to
[`npmatch::np_compare()`](https://nonprofit-open-data-collective.github.io/npmatch/reference/np_compare.html)
(`addr_freq =`), which annotates each pair with `addr_shared`,
`addr_units`, `addr_unit_shared` and a reviewer-facing `addr_note`, and
gates the suite credit in `np_score(method = "hier")`.

## See also

[`np_name_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_freq.md),
[`npmatch::np_compare()`](https://nonprofit-open-data-collective.github.io/npmatch/reference/np_compare.html)
