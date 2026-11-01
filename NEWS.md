# npnormalize 0.1.4

A new address column asked for in
[#9](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/9),
and a defect the measurement for it turned up. Both were measured against the
3,687,435-row unified BMF; the scan is `dev/scan-box-component.R`, kept as the
record, the way `scan-unit-designators.R` is for the designator list.

* **`street_has_box`**, a second question about a box: does the street *carry*
  a box component, whether or not the whole street is one. `is_po_box` cannot
  answer it and should not be widened to — it is the gate that blanks the
  address key in `np_addr_key()`, so widening it would stop counting records at
  streets that are genuine buildings. Filers write the street on line 1 ending
  in the box *word* and carry the box *number* alone on line 2, and a consumer
  holding that bare number had nothing to tell a box number from a door:

  | raw street | `street_key` | `is_po_box` | `street_has_box` |
  |---|---|---|---|
  | `211 EMMET STREET SOUTH PO BOX` | `211 EMMET ST S PO BOX` | `FALSE` | `TRUE` |
  | `300 KENAN CENTER DRIVE - CAMPUS BOX` | `300 KENAN CENTER DR CAMPUS BOX` | `FALSE` | `TRUE` |
  | `ONE HARRISON PLAZA BOX 5079` | `ONE HARRISON PLAZA BOX 5079` | `FALSE` | `TRUE` |
  | `PO BOX A` | `PO BOX A` | `FALSE` | `TRUE` |
  | `PO BOX 1367` | `PO BOX 1367` | `TRUE` | `TRUE` |
  | `22009 BOX ELDER RD` | `22009 BOX ELDER RD` | `FALSE` | `FALSE` |

  `is_po_box` implies `street_has_box` on every row, because the flag is read
  from the key `np_normalize()` publishes — so a consumer holding a cached
  `street_key` can recompute it without re-normalizing.

  The box word has to **end** the key, with at most digits or a single letter
  after it. That anchor is the whole guard, and the reason the pattern is not
  the unanchored `BOX` pfmatch keeps locally: a bare `\bBOX\b` matches 2,099
  rows the anchored form does not, and 127 of them are streets *named* for a
  box (`BOX SPGS RD`,
  `BOX ELDER ST`, `BOX RD`). The anchored form flags 1 of those 405 rows, and
  that one is a box. `BOXWOOD` and `BOXER` never match either way.

  The flag adds 11,982 rows (0.325%) to the 579,602 `is_po_box` already
  reports: 562 a street then a bare `BOX`, 10,345 a street then `BOX <number>`,
  and 1,075 a lettered box (`PO BOX A` … `PO BOX Z`, which `.np_pobox_pat`
  misses because it requires digits). `DRAWER` and `BIN` were measured and left
  out at 55 and 28 rows, against a false positive already visible at that
  volume (`1206 GRAIN BIN RD`).

  **`street_unit` is deliberately not changed by this.** The flag says the
  street has a box, not that a companion number is that box's — the street can
  name a suite as well (`4347 W NORTHWEST HWY STE 130 BOX`), and that call
  belongs to whoever holds the second line. 0.1.2 already removed the sharp
  edge by making `np_unit_id("400891")` `NA`; this adds the positive signal a
  consumer can key on, and lets pfmatch replace its local `.PF_BOX_RE` with a
  column.
* **`.np_parse_street()` now treats only an anchored box as a box.** Its gate
  was an unanchored `grepl("\\bBOX\\b")`, which overwrote the parse of 14,014
  BMF rows (0.380%) whose street merely carries or is named for a box, on rows
  where `is_po_box` said `FALSE`:

  | `street_key` | 0.1.3 `street_num` / `street_name` | 0.1.4 |
  |---|---|---|
  | `ONE HARRISON PLZ BOX 5079` | `5079` / `PO BOX` | `NA` / `ONE HARRISON PLZ BOX 5079` |
  | `22009 BOX ELDER RD` | `NA` / `PO BOX` | `22009` / `BOX ELDER` (type `RD`) |
  | `211 EMMET ST S PO BOX` | `NA` / `PO BOX` | `211` / `EMMET ST S PO BOX` |
  | `PO BOX 12` | `12` / `PO BOX` | `12` / `PO BOX` |

  A BOX-named street used to lose its house number to a box number it does not
  have, and two records agreed on a `street_num` neither had. The parse and
  `is_po_box` can no longer disagree about what a box is, which a test asserts.
* **This moves the signature**, to `v1-1179714ce1e9d31f`. `street_has_box` is a
  new cached column and `street_num` / `street_name` move on the rows above, so
  matchdb must rebuild its derived columns again — the 0.1.3 rebuild
  ([matchdb#29](https://github.com/Nonprofit-Open-Data-Collective/matchdb/issues/29))
  had already closed, so this does not ride along with it.
* npmatch needs no change: it reads `is_po_box` only for `geo_pobox`, and the
  new column is additive.

# npnormalize 0.1.3

Two parsing rules that 0.1.2 carried further, found when matchdb rebuilt under
it ([matchdb#29](https://github.com/Nonprofit-Open-Data-Collective/matchdb/issues/29)).
Neither changes `street_key`, so blocking is unaffected.

* A line naming several units keeps the most specific one, not the first one
  written. Every unit is cut from `street_key`, but `street_unit` holds one,
  and the first was often the one that does not tell occupants apart:

  | raw street | 0.1.2 `street_unit` | 0.1.3 |
  |---|---|---|
  | `1 BETHANY RD BUILDING 1 STE 5` | `BLDG 1` | `STE 5` |
  | `2125 BISCAYNE BLVD STE 204 # 22915` | `STE 204` | `# 22915` |
  | `1633 MAIN ST STE A PMB 175` | `STE A` | `PMB 175` |
  | `123 MAIN ST RM 3 FL 2` | `RM 3` | `RM 3` |

  The rank (`.np_unit_rank`) runs building < floor or area < door < mailbox,
  and between two of one rank the last wins, because an address is written
  from the outside in. In matchdb's 13.0M address strings, 56,466 name two or
  more units, and the pick changes for 54,936 of them (17,724 current address
  rows), mostly a mail store's suite giving way to the customer's box. The
  second address line is read by the same rule.
* The house number is a whole leading token. An ordinal street has none:
  `16TH ST` gave `street_num` `16T` and `street_name` `H`, so two such records
  agreed on a house number neither has. Grid numbers stay whole (`16W540 BLUFF
  RD`, which gave `16W`), and a number run into the street name is its digits
  (`921AIRPORT SERVICE RD` gives `921` on `AIRPORT SERVICE`, not `921A` on
  `IRPORT SERVICE`) unless they could begin an ordinal. 19,909 of matchdb's
  address strings change.
* **This moves the signature**, to `v1-592912060053c4c3`. Cached
  `street_unit`, `street_unit_id`, `street_num` and `street_name` values must
  be rebuilt.

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
