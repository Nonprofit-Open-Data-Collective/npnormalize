<div id="main" class="col-md-9" role="main">

# Changelog

<div class="section level2">

## npnormalize 0.1.6

The policy question behind
[#13](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/13),
answered family by family, and the signal a blanked box was throwing
away. `np_addr_key()` answers *same building?*, so every mail-delivery
address has to be blank in it — leaving one in does not add a wrong row,
it builds a cluster, because every box-holder in a ZIP becomes a
co-tenant of every other and the address-sharing statistics then read
that crowd as an office building. Four families were measured against
that rule and two of them keep their key.

<div class="section level3">

### The box vocabulary takes the spellings [#13](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/13) measured

`.np_box_head` gains `PO BX`, `PB` and `PB BOX`, `P BOX` and its
zero-for-the-O typo `P B0X`, `POSTAL OFC BOX`, `APDO`, and the `DRAWER`
family (bare, or behind `PO` / `POST OFC` / `POSTAL`). Over the
3,687,435-row unified BMF that is **58 more rows detected and 0 lost**,
in 54 keys, every one of which is a box a filer spelled unusually.

The identifier had to move with it. `.np_box_identifier()` read the
first digit run in the whole key, which was correct only while no
designator contained a digit — `P B0X 102` took the `0` out of `B0X` and
keyed all four of those rows to `PO BOX 0`, which is the lettered-box
collapse of
[#12](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/12)
in a new place: two different boxes landing on one address. The digits
are now read from what follows the designator, still anywhere after it,
because a box number is routinely followed by more text
(`PO BOX 102175 KOOSER RD`). Corpus-wide the identifier moved on **0**
rows that 0.1.5 already called boxes.

Measured and declined, so the decision is on the record rather than the
spelling being missed: a bare `BX` (1 row), the unabbreviated `APARTADO`
and `BUZON` (7), and `CALLER BOX` (1). `APARTADO` is the unabbreviated
form of the `APDO` that was adopted, so it is the first candidate if
this is revisited.

</div>

<div class="section level3">

### `is_mail_only`, a second gate on the address key

A new column and a new pattern for the designators that have no building
*and* no identifier to compare: `GENERAL DELIVERY` and `GEN DEL` (158
rows), military mail — `PSC` 236, `CMR` 63, `APO` 12, `FPO` 7, `DPO` 0 —
and the university mail drawers named by two letters
(`DRAWER AA UNIVERSITY OF MONTEVALLO`, 20 rows). 496 rows that
`is_po_box` cannot see.

`GENERAL DELIVERY` is the clearest case in the corpus: 117 rows whose
street is that exact string and nothing else, so the key was
`GENERAL DELIVERY <zip>` and every general-delivery filer in a ZIP was
counted as one building’s tenants.

Two things it deliberately does not do. The street key is **not**
rewritten — there is no box number to rewrite it to, and the string is
the only thing the row says — and the flag is reported **disjoint** from
`is_po_box`, so the two partition the buildingless addresses rather than
overlapping on the drawers. A `DRAWER` sits in both vocabularies because
`DRAWER B` has a comparable identifier and `DRAWER JJ EMORY UNIVERSITY`
does not, and a caller should not have to know that. The address-key
blank is the union either way, which is why `np_pattern("mailonly")`
hands out the raw pattern: a SQL copy ORs the two and lands in the same
place.

Anchored at `^` with a word boundary and no identifier, none of these
reaches a street: 0 of the 3,998 rural-route keys, 0 `BIN`, 0 of the
`BOX ELDER` / `BOX SPGS` family, and `GEN DELANEY ST` is safe because
`\b` cannot run into a street name. The one row it takes from a KEEP
family is `APO MAILBOX 637 REED UN BLDG`, which is an APO address.

</div>

<div class="section level3">

### What keeps its address key, and why

A **rural route** does, on the reasoning that it is unlike a box: it is
a unique delivery point, so two filers at `RR 1 BOX 8` in one ZIP really
are at one place.
[#13](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/13)
worried that routes would crowd instead; measured, they do not. Across
4,606 route-with-box address keys the most crowded holds **5** EINs, and
across 570 bare-route keys, **2**. The `street_num` collision
[#13](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/13)
raised is real — `RR 1` parses `street_num` `1` — but with clusters that
size it has nothing to amplify.

A **MAILBOX** (123 rows) and a **BIN** (24) do too: both sit at a real
street address, which the key keeps. `BIN` also still has a visible
false positive at its volume, `1206 GRAIN BIN RD`.

Together the two gates blank **581,166 of 3,687,435 rows**, 554 more
than 0.1.5. The address key is un-blanked on 0 rows and otherwise
unchanged on 0, and the distinct address-key count falls by 538.

</div>

<div class="section level3">

### `mail_key`: what a blanked box still tells you

Blanking a box says two filers are not in one building. That is true,
and it is all it says — but two organizations collecting mail from the
*same* box are very likely administered by the same people, which is a
different claim and a useful one. `mail_key` is the complement of the
address key and carries it: the box and its ZIP (`"PO BOX 1234 59801"`),
blank for everything else, including the mail-only designators, because
`GENERAL DELIVERY 59801` would rebuild exactly the false crowd the blank
just removed.

It is idempotent on a rewritten `street_key`, which matters because
matchdb caches that column and may hand back either form: `POB 25161`,
`P O 25161` and `PO BOX 25161` all key to `PO BOX 25161 <zip>`.
Corpus-wide 213 mail keys are built from more than one street key and
every one is the same box spelled differently.

**The count is not optional.** 580,670 box rows fall into 496,830 mail
keys, 7.43% of them shared by two or more EINs, and 20.79% of
box-holding EINs sit on a shared box. But the populations at either end
want opposite treatment: 30,097 of the 36,910 shared boxes hold exactly
two EINs and 3,829 hold three — an organization and its foundation, a
parent and its chapter — while 678 hold ten or more and the most
crowded, `PO BOX 653067` in ZIP 75265, holds **3,626**. That is a
service bureau, and reading it as common administration would link 3,626
unrelated organizations to each other. `np_mail_freq()` is the
counterpart to `np_addr_freq()`’s `share_min` for exactly this, and its
documentation carries the numbers.

</div>

<div class="section level3">

### Published for consumers

-   `np_is_mail_only()` joins `np_is_po_box()` and `np_has_box()` for a
    caller holding one free-text line.
-   `np_mail_key()` joins `np_addr_key()`; `np_mail_freq()` joins
    `np_name_freq()` and `np_addr_freq()`.
-   `np_pattern("mailonly")` joins `"pobox"`, `"box"` and `"unit_id"`.
    `test-portability.R` now runs all four through R’s TRE and DuckDB’s
    RE2 over a 45-key fixture and asserts they agree, and it asserts two
    things a hand-ported SQL macro gets wrong: that a macro reading only
    `"pobox"` is narrower than `np_addr_key()`, and that the identifier
    is capture group 2 — the drawer alternative nests a group inside the
    head, and it has to stay non-capturing or group 2 silently becomes
    the drawer prefix.

</div>

<div class="section level3">

### Signature

This moves `np_normalize_signature()` to `v1-d49b18cc81ab79fb`.
`is_po_box`, `street_key`, `street_num` and the address key all move on
the rows above, and `is_mail_only` and `mail_key` are new columns, so
**matchdb must rebuild its derived columns** — and should take
`.md_pobox_pat` from `np_pattern("pobox")` and add the `"mailonly"` gate
in the same change, or its `md_place_key()` macro will be narrower than
`np_addr_key()` in two separate ways. npmatch needs no change: it reads
`is_po_box` only, for `geo_pobox`.

R CMD check: Status OK. 216 test assertions pass. # npnormalize 0.1.5

An audit of PO-box detection against the 3,687,435-row unified BMF, the
one defect it found that is this package’s to fix, and the first half of
a fix for the four packages drifting apart on box patterns. The audit is
`dev/audit-pobox.R`, kept as the record; it reads the **raw** street
line rather than the key, because a spelling can only be judged against
what the filer actually wrote.

</div>

<div class="section level3">

### What detection looks like today

Nothing is being vacuumed up. `is_po_box` is 579,602 rows (15.718%) in
78,936 distinct keys, and of the 1,000 sampled detections (weighted by
row), **none** lacks a box word on the raw line. Across the whole corpus
only 30 rows do, and every one is a box written without a space —
`PO762`, `PO25762`. By spelling:

| what matched                   |    rows |
|--------------------------------|--------:|
| `PO BOX` / `P O BOX` / `POBOX` | 578,684 |
| a bare `BOX`                   |     682 |
| `PO` / `P O`, no box word      |     164 |
| `POB` / `PO B`                 |      72 |

The precision edge that does exist is the dual address line: 1,141 rows
carry text after the box number, 136 of them a whole street
(`PO BOX 102175 KOOSER RD`), and blanking the address key discards that
street. Left as is — it is 0.031% of detections and the alternative is
parsing two addresses out of one line.

</div>

<div class="section level3">

### `is_po_box` now reads a lettered box

[#12](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/12).
A box identifier is digits **or a single letter where the key ends**, so
`PO BOX A` through `PO BOX Z` are boxes:

-   1,010 rows (0.027%) in 41 keys, 982 of them the `PO BOX <letter>`
    alphabet, led by B (119) and A (116). The other 28 are box lines
    truncated in the filing — `PO BO`, `POB`, `BOX R`. No street in the
    corpus has a whole key of a designator plus one letter.
-   There is no building at `PO BOX Q`, but the digits-only pattern
    meant `np_addr_key()` kept their keys and counted their holders as a
    building’s tenants: **105 of their 825 address keys hold two or more
    EINs**, up to 15 at `PO BOX B 75785`.
-   The anchor sits on the letter branch only. A box *number* is
    routinely followed by more text, so anchoring the whole identifier
    would have dropped the 1,141 rows above; a test asserts the widened
    pattern still flags every spelling the digits form flagged, and the
    pattern added 41 keys and lost 0 over the full corpus.

**The letter has to survive the rewrite**, and a new helper
`.np_box_identifier()` is what makes it: `np_normalize()`’s
`"PO BOX <id>"` rewrite read `[0-9]+`, so a widened flag alone would
have rewritten `PO BOX A` and `PO BOX B` to the same bare `PO BOX` — two
different boxes collapsed onto one address, worse than not flagging
them. `.np_parse_street()` reads the same helper, so the key and
`street_num` always name the same box. That also recovers 236 rows whose
box number was `NA`: the old parse required the literal word `BOX`, so
`POB 25161` and `PO 1609` lost theirs although the key says
`PO BOX 25161`.

</div>

<div class="section level3">

### One vocabulary, and a way for other packages to read it

The four packages had drifted. pfmatch kept `.PF_BOX_RE`, an
*unanchored* `BOX` that claims 127 BMF rows whose street is merely
*named* for a box (`BOX ELDER ST`, `BOX SPGS RD`); matchdb keeps
`.md_pobox_pat`, a hand-typed copy of this package’s pattern, because
DuckDB’s R client registers data frames, not scalar UDFs, so a SQL macro
cannot call `np_addr_key()`.

-   `.np_box_head` and `.np_box_id` are the vocabulary; `.np_pobox_pat`
    is composed from them, and `.np_unit_id_strip` is lifted out of
    `np_unit_id()` for the same reason. Only the composed values are in
    the signature registry — editing a piece still moves the signature,
    rearranging the pieces does not.
-   **`np_is_po_box()`** and **`np_has_box()`** answer the two box
    questions for a caller holding one free-text line, which is what a
    consumer keeping its own `BOX` regex actually wanted. `np_has_box()`
    no longer depends on the rewrite, so `POBOX 12` answers `TRUE`
    (there is no word boundary before `BOX`, so the tail pattern alone
    cannot see it).
-   **`np_pattern()`** hands out the literals — `"pobox"`, `"box"`,
    `"unit_id"` — for a consumer that cannot call an R function at all.
    The patterns are written in the subset R’s own engine and RE2 share,
    with no lookaround (which R rejects too, without `perl = TRUE`) and
    no `\d`.
-   `test-portability.R` runs each published pattern through **both**
    engines over one fixture and asserts they agree, and asserts the
    composition. That is what keeps a SQL copy honest rather than merely
    hand-ported.

</div>

<div class="section level3">

### Downstream

-   **This moves the signature**, to `v1-533f186c123357cf`: `is_po_box`,
    `street_key`, `street_num` and the address key all move on the rows
    above, so matchdb must rebuild its derived columns. It should take
    `.md_pobox_pat` from `np_pattern("pobox")` in the same change, or
    its `md_place_key()` macro will be narrower than `np_addr_key()`.
-   **pfmatch** can now replace `.PF_BOX_RE` with
    `npnormalize::np_has_box()`.
-   **npmatch** needs no change: it reads `is_po_box` only for
    `geo_pobox`.

</div>

<div class="section level3">

### Measured and not changed

-   The bare designator — a key that is `PO BOX` and nothing else, 460
    rows — is still not a box, and `np_addr_key()` still keys it.
    [#12](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/12)
    suspected this collapsed a ZIP’s boxes onto one address; it does
    not. Those 460 rows hold 455 address keys, 4 of which have two or
    more EINs, at most 3.
-   The designator families `is_po_box` does **not** see are left for
    their own issue, with the measurement in `dev/audit-pobox.R` section
    C: rural routes carrying a box (`RR 1 BOX 8`, 4,625 rows), military
    `PSC` / `APO` / `FPO` (343), `GENERAL DELIVERY` (164), `DRAWER`
    (77), and the long tail of `PO BX`, `BX`, `PB`, `POSTAL`, `APARTADO`
    and `BUZON` (a dozen rows each or fewer). `PMB` (13,700 rows) is
    deliberately not among them: a private mailbox sits at a real street
    address, which the key keeps.

</div>

</div>

<div class="section level2">

## npnormalize 0.1.4

A new address column asked for in
[#9](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/9),
and a defect the measurement for it turned up. Both were measured
against the 3,687,435-row unified BMF; the scan is
`dev/scan-box-component.R`, kept as the record, the way
`scan-unit-designators.R` is for the designator list.

-   **`street_has_box`**, a second question about a box: does the street
    *carry* a box component, whether or not the whole street is one.
    `is_po_box` cannot answer it and should not be widened to — it is
    the gate that blanks the address key in `np_addr_key()`, so widening
    it would stop counting records at streets that are genuine
    buildings. Filers write the street on line 1 ending in the box
    *word* and carry the box *number* alone on line 2, and a consumer
    holding that bare number had nothing to tell a box number from a
    door:

    | raw street                            | `street_key`                     | `is_po_box` | `street_has_box` |
    |---------------------------------------|----------------------------------|-------------|------------------|
    | `211 EMMET STREET SOUTH PO BOX`       | `211 EMMET ST S PO BOX`          | `FALSE`     | `TRUE`           |
    | `300 KENAN CENTER DRIVE - CAMPUS BOX` | `300 KENAN CENTER DR CAMPUS BOX` | `FALSE`     | `TRUE`           |
    | `ONE HARRISON PLAZA BOX 5079`         | `ONE HARRISON PLAZA BOX 5079`    | `FALSE`     | `TRUE`           |
    | `PO BOX A`                            | `PO BOX A`                       | `FALSE`     | `TRUE`           |
    | `PO BOX 1367`                         | `PO BOX 1367`                    | `TRUE`      | `TRUE`           |
    | `22009 BOX ELDER RD`                  | `22009 BOX ELDER RD`             | `FALSE`     | `FALSE`          |

    `is_po_box` implies `street_has_box` on every row, because the flag
    is read from the key `np_normalize()` publishes — so a consumer
    holding a cached `street_key` can recompute it without
    re-normalizing.

    The box word has to **end** the key, with at most digits or a single
    letter after it. That anchor is the whole guard, and the reason the
    pattern is not the unanchored `BOX` pfmatch keeps locally: a bare
    `\bBOX\b` matches 2,099 rows the anchored form does not, and 127 of
    them are streets *named* for a box (`BOX SPGS RD`, `BOX ELDER ST`,
    `BOX RD`). The anchored form flags 1 of those 405 rows, and that one
    is a box. `BOXWOOD` and `BOXER` never match either way.

    The flag adds 11,982 rows (0.325%) to the 579,602 `is_po_box`
    already reports: 562 a street then a bare `BOX`, 10,345 a street
    then `BOX <number>`, and 1,075 a lettered box (`PO BOX A` …
    `PO BOX Z`, which `.np_pobox_pat` misses because it requires
    digits). `DRAWER` and `BIN` were measured and left out at 55 and 28
    rows, against a false positive already visible at that volume
    (`1206 GRAIN BIN RD`).

    **`street_unit` is deliberately not changed by this.** The flag says
    the street has a box, not that a companion number is that box’s —
    the street can name a suite as well
    (`4347 W NORTHWEST HWY STE 130 BOX`), and that call belongs to
    whoever holds the second line. 0.1.2 already removed the sharp edge
    by making `np_unit_id("400891")` `NA`; this adds the positive signal
    a consumer can key on, and lets pfmatch replace its local
    `.PF_BOX_RE` with a column.

-   **`.np_parse_street()` now treats only an anchored box as a box.**
    Its gate was an unanchored `grepl("\\bBOX\\b")`, which overwrote the
    parse of 14,014 BMF rows (0.380%) whose street merely carries or is
    named for a box, on rows where `is_po_box` said `FALSE`:

    | `street_key`                | 0.1.3 `street_num` / `street_name` | 0.1.4                              |
    |-----------------------------|------------------------------------|------------------------------------|
    | `ONE HARRISON PLZ BOX 5079` | `5079` / `PO BOX`                  | `NA` / `ONE HARRISON PLZ BOX 5079` |
    | `22009 BOX ELDER RD`        | `NA` / `PO BOX`                    | `22009` / `BOX ELDER` (type `RD`)  |
    | `211 EMMET ST S PO BOX`     | `NA` / `PO BOX`                    | `211` / `EMMET ST S PO BOX`        |
    | `PO BOX 12`                 | `12` / `PO BOX`                    | `12` / `PO BOX`                    |

    A BOX-named street used to lose its house number to a box number it
    does not have, and two records agreed on a `street_num` neither had.
    The parse and `is_po_box` can no longer disagree about what a box
    is, which a test asserts.

-   **This moves the signature**, to `v1-1179714ce1e9d31f`.
    `street_has_box` is a new cached column and `street_num` /
    `street_name` move on the rows above, so matchdb must rebuild its
    derived columns again — the 0.1.3 rebuild
    ([matchdb#29](https://github.com/Nonprofit-Open-Data-Collective/matchdb/issues/29))
    had already closed, so this does not ride along with it.

-   npmatch needs no change: it reads `is_po_box` only for `geo_pobox`,
    and the new column is additive.

</div>

<div class="section level2">

## npnormalize 0.1.3

Two parsing rules that 0.1.2 carried further, found when matchdb rebuilt
under it
([matchdb#29](https://github.com/Nonprofit-Open-Data-Collective/matchdb/issues/29)).
Neither changes `street_key`, so blocking is unaffected.

-   A line naming several units keeps the most specific one, not the
    first one written. Every unit is cut from `street_key`, but
    `street_unit` holds one, and the first was often the one that does
    not tell occupants apart:

    | raw street                           | 0.1.2 `street_unit` | 0.1.3     |
    |--------------------------------------|---------------------|-----------|
    | `1 BETHANY RD BUILDING 1 STE 5`      | `BLDG 1`            | `STE 5`   |
    | `2125 BISCAYNE BLVD STE 204 # 22915` | `STE 204`           | `# 22915` |
    | `1633 MAIN ST STE A PMB 175`         | `STE A`             | `PMB 175` |
    | `123 MAIN ST RM 3 FL 2`              | `RM 3`              | `RM 3`    |

    The rank (`.np_unit_rank`) runs building \< floor or area \< door \<
    mailbox, and between two of one rank the last wins, because an
    address is written from the outside in. In matchdb’s 13.0M address
    strings, 56,466 name two or more units, and the pick changes for
    54,936 of them (17,724 current address rows), mostly a mail store’s
    suite giving way to the customer’s box. The second address line is
    read by the same rule.

-   The house number is a whole leading token. An ordinal street has
    none: `16TH ST` gave `street_num` `16T` and `street_name` `H`, so
    two such records agreed on a house number neither has. Grid numbers
    stay whole (`16W540 BLUFF   RD`, which gave `16W`), and a number run
    into the street name is its digits (`921AIRPORT SERVICE RD` gives
    `921` on `AIRPORT SERVICE`, not `921A` on `IRPORT SERVICE`) unless
    they could begin an ordinal. 19,909 of matchdb’s address strings
    change.

-   **This moves the signature**, to `v1-592912060053c4c3`. Cached
    `street_unit`, `street_unit_id`, `street_num` and `street_name`
    values must be rebuilt.

</div>

<div class="section level2">

## npnormalize 0.1.2

Two unit-extraction bugs reported from pfmatch, which parses the
free-text secondary-unit line of Form 990-PF Part XIV Table 3a with this
package
([#7](https://github.com/Nonprofit-Open-Data-Collective/npnormalize/issues/7)).

-   `BUILDING` is now a unit designator, as its abbreviation `BLDG`
    already was. The unit is extracted from the raw street, while
    `.np_street_types` contracts `BUILDING -> BLDG` two lines later in
    `np_normalize()`, so the pattern never saw the one spelling it
    recognized and the two spellings of one address disagreed on both
    outputs:

    | raw street                       | `street_key`                     | `street_unit` |
    |----------------------------------|----------------------------------|---------------|
    | `100 CAMPUS CENTER BUILDING 86E` | was `100 CAMPUS CENTER BLDG 86E` | was `NA`      |
    | `100 CAMPUS CENTER BLDG 86E`     | `100 CAMPUS CENTER`              | `BLDG 86E`    |

    Both now key as `100 CAMPUS CENTER` with unit `BLDG 86E`, so the
    pair blocks and compares. `BUILDING` is still an ordinary street
    word where no identifier follows it (`1 EMPIRE STATE BUILDING`,
    `4 BUILDING COMMISSION RD`).

    -   A test asserts the general case over `.np_street_types`: every
        key whose abbreviation is a designator must be a designator
        itself. This class of bug is invisible one case at a time,
        because the street key looks right.
    -   **This moves the signature**, to `v1-6d90b52d8b781673`. Any
        address spelling the designator out keys differently, so cached
        keys and the corpus statistics built on them must be rebuilt.

-   `np_unit_id()` is gated by the designator pattern, so it returns
    `NA` for a line that names no unit instead of reducing whatever it
    was given. It is exported, and a caller handing it a raw address
    line got confident nonsense with no signal: `"PO BOX 1367"` gave
    `"BOX1367"`, `"LAS VEGAS"` gave `"VEGAS"`, `"114 HIGH ST"` gave
    `"114HIGHST"`. All three are now `NA`.

    -   A bare identifier with no designator (`"300"`) is now `NA` as
        well, because a digit string alone is as often a box number or a
        record counter as a door. Pass a dedicated unit column as
        `np_extract_unit()`’s `unit` argument, where a bare value is
        still accepted.
    -   `np_normalize()` is unaffected: it calls the internal
        `.np_unit_id()` on an already-extracted `street_unit`, and
        `street_unit_id` does not change.

-   New exported `np_extract_unit()`, the single-vector entry point onto
    that gate: it reads the unit out of one free-text address line
    exactly as `np_normalize()` fills `street_unit`. A consumer parsing
    one line no longer has to normalize a one-column data frame to reach
    the gate.

</div>

<div class="section level2">

## npnormalize 0.1.1

-   New exported `np_unit_id()`. It reduces a suite as `np_normalize()`
    writes it in `street_unit` (`"STE 300"`, `"# 300"`, `"STE D-2"`) to
    its identifier (`"300"`, `"300"`, `"D2"`), which is the
    `street_unit_id` column.
    -   matchdb’s `md_unit_id()` needs a public function for this,
        because it can no longer find npmatch’s internal `.np_unit_id()`
        once npmatch imports this package (step 3 of
        `dev/EXTRACTION.md`).
    -   Like the other four wrappers, it adds nothing of its own, so the
        signature is unchanged: `np_normalize_signature()` is still
        `v1-3e7b9f9d59bbb19e`.

</div>

<div class="section level2">

## npnormalize 0.1.0

-   First release. npmatch’s normalizer moved into its own package,
    every function name and body unchanged
    (`dev/extract-from-npmatch.R`, from `npmatch@de52bb9`):
    -   the rule tables;
    -   `np_normalize()`, `np_name_core()` and `np_name_placeholder()`;
    -   the corpus statistics (`np_name_freq()`, `np_token_idf()`,
        `np_addr_freq()`, `np_stopwords()`);
    -   the blocking tokenizer;
    -   `np_normalize_signature()`.
-   `np_normalize_signature()` is `v1-3e7b9f9d59bbb19e`, as it was in
    npmatch, and a test pins it.
-   New exported wrappers for the internals npmatch’s matching code
    calls: `np_tokenize()`, `np_doc_freq()`, `np_addr_key()` and
    `np_state_abb()`. They are not part of the signature.

</div>

</div>
