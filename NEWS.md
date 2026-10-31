# npnormalize 0.1.2

Two unit-extraction bugs reported from pfmatch, which parses the free-text
secondary-unit line of Form 990-PF Part XIV Table 3a with this package
([#7](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/7)).

* `BUILDING` is now a unit designator, as its abbreviation `BLDG` already was.
  The unit is extracted from the raw street, while `.np_street_types` contracts
  `BUILDING -> BLDG` two lines later in `np_normalize()`, so the pattern never
  saw the one spelling it recognized and the two spellings of one address
  disagreed on both outputs:

  | raw street | `street_key` | `street_unit` |
  |---|---|---|
  | `100 CAMPUS CENTER BUILDING 86E` | was `100 CAMPUS CENTER BLDG 86E` | was `NA` |
  | `100 CAMPUS CENTER BLDG 86E` | `100 CAMPUS CENTER` | `BLDG 86E` |

  Both now key as `100 CAMPUS CENTER` with unit `BLDG 86E`, so the pair blocks
  and compares. `BUILDING` is still an ordinary street word where no identifier
  follows it (`1 EMPIRE STATE BUILDING`, `4 BUILDING COMMISSION RD`).
  * A test asserts the general case over `.np_street_types`: every key whose
    abbreviation is a designator must be a designator itself. This class of bug
    is invisible one case at a time, because the street key looks right.
  * **This moves the signature**, to `v1-6d90b52d8b781673`. Any address
    spelling the designator out keys differently, so cached keys and the corpus
    statistics built on them must be rebuilt.
* `np_unit_id()` is gated by the designator pattern, so it returns `NA` for a
  line that names no unit instead of reducing whatever it was given. It is
  exported, and a caller handing it a raw address line got confident nonsense
  with no signal: `"PO BOX 1367"` gave `"BOX1367"`, `"LAS VEGAS"` gave
  `"VEGAS"`, `"114 HIGH ST"` gave `"114HIGHST"`. All three are now `NA`.
  * A bare identifier with no designator (`"300"`) is now `NA` as well, because
    a digit string alone is as often a box number or a record counter as a
    door. Pass a dedicated unit column as `np_extract_unit()`'s `unit`
    argument, where a bare value is still accepted.
  * `np_normalize()` is unaffected: it calls the internal `.np_unit_id()` on an
    already-extracted `street_unit`, and `street_unit_id` does not change.
* New exported `np_extract_unit()`, the single-vector entry point onto that
  gate: it reads the unit out of one free-text address line exactly as
  `np_normalize()` fills `street_unit`. A consumer parsing one line no longer
  has to normalize a one-column data frame to reach the gate.

# npnormalize 0.1.1

* New exported `np_unit_id()`. It reduces a suite as `np_normalize()` writes it
  in `street_unit` (`"STE 300"`, `"# 300"`, `"STE D-2"`) to its identifier
  (`"300"`, `"300"`, `"D2"`), which is the `street_unit_id` column.
  * matchdb's `md_unit_id()` needs a public function for this, because it can
    no longer find npmatch's internal `.np_unit_id()` once npmatch imports this
    package (step 3 of `dev/EXTRACTION.md`).
  * Like the other four wrappers, it adds nothing of its own, so the signature
    is unchanged: `np_normalize_signature()` is still `v1-3e7b9f9d59bbb19e`.

# npnormalize 0.1.0

* First release. npmatch's normalizer moved into its own package, every function
  name and body unchanged (`dev/extract-from-npmatch.R`, from `npmatch@de52bb9`):
  * the rule tables;
  * `np_normalize()`, `np_name_core()` and `np_name_placeholder()`;
  * the corpus statistics (`np_name_freq()`, `np_token_idf()`,
    `np_addr_freq()`, `np_stopwords()`);
  * the blocking tokenizer;
  * `np_normalize_signature()`.
* `np_normalize_signature()` is `v1-3e7b9f9d59bbb19e`, as it was in npmatch, and
  a test pins it.
* New exported wrappers for the internals npmatch's matching code calls:
  `np_tokenize()`, `np_doc_freq()`, `np_addr_key()` and `np_state_abb()`. They
  are not part of the signature.
