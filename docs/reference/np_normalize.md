<div id="main" class="col-md-9" role="main">

# Normalize a query or reference frame

<div class="ref-description section level2">

Brings entity names and addresses onto a common, matchable form (parity
with the BMF `org_name_join` field) and extracts the token-level
features the veto layer needs. Adds columns alongside the canonical
ones:

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_normalize(data)
```

</div>

</div>

<div class="section level2">

## Arguments

-   data:

    An `np_query` or `np_reference` frame from `npmatch::np_query()` /
    `npmatch::np_reference()`.

</div>

<div class="section level2">

## Value

The same frame with the normalization columns added.

</div>

<div class="section level2">

## Details

-   `name_key` cleaned, abbreviation-standardized, legal-suffix-stripped

-   `dba_key` the DBA name under the same normalization (for
    cross-matching)

-   `name_full` cleaned name *with* suffix retained

-   `name_core` exact-lookup key: `name_full` without connector words
    and legal forms anywhere (THE, OF, AND, INC, LLC ...), keeping
    FOUNDATION, TRUST, FUND (see `np_name_core()`)

-   `name_placeholder` `TRUE` for names that are not names ("SEE
    SCHEDULE O", "N/A", no letters); `npmatch::np_block()` gives such
    query rows no candidates

-   `name_form` detected legal form (INC / LLC / CORP / ...), or `NA`

-   `name_gen`, `name_gen_rank` **vestigial** — a person-name generation
    marker (`JR` / `SR`, ranked `SR` = 1, `JR` = 2) inherited from
    npmatch's person-matching lineage. Organisations do not have
    generations; nothing in the package consumes these and they are not
    useful features. Retained only for column compatibility with
    existing labeled extracts. See `npmatch::np_default_rules()`.

-   `name_nums` space-joined embedded digit tokens (chapter/local
    numbers)

-   `name_ord` canonical ordinal rank(s) found in the name

-   `street_key` USPS-standardized street with unit stripped

-   `street_num` leading house / box number

-   `street_name` street body with the number, type, and unit removed

-   `street_type` trailing street type (ST / AVE / BLVD / WAY / ...), or
    `NA`

-   `street_unit` the suite / floor / unit as written, normalized to ""
    ("STE 300", "FL 2", "# 12"). Read from the street line, or from the
    `unit` column when the street line names none

-   `street_unit_id` the identifier alone, separators dropped ("STE D-2"
    -> "D2"). Two records are compared on this, so a BMF "STE 300" and a
    source "# 300" are recognised as one office

-   `is_po_box` `TRUE` if the street *is* a mail receptacle with an
    identifier, else `FALSE`. Any spelling of the designator
    (`PO BOX 12`, `P O BOX 12`, `POBOX 12`, `POB 12`, `PO B 12`,
    `PO 12`, `BOX 12`, `PO BX 12`, `PB 12`, `PB BOX 12`, `P B0X 12`,
    `POSTAL OFC BOX 12`, `APDO 12`, `DRAWER B`, `PO DRAWER D`,
    `POSTAL DRAWER 12`) and any identifier – digits, or a single letter
    where the key ends, so the lettered boxes `PO BOX A` through
    `PO BOX Z` count as boxes too. One of the two gates that blank the
    address key in `np_addr_key()`

-   `is_mail_only` `TRUE` if the street names a mail-delivery point that
    has no building behind it *and* no identifier this package will
    reduce to a box: `GENERAL DELIVERY`, `GEN DEL`, military mail
    (`PSC 303 BOX 24`, `CMR 467 BOX 7000`, `APO`, `FPO`, `DPO`) and a
    university mail drawer named by two letters
    (`DRAWER JJ EMORY UNIVERSITY`). The other gate on `np_addr_key()`,
    and disjoint from `is_po_box` by construction, so the two flags
    partition the buildingless addresses. Unlike a box the key is *not*
    rewritten, because there is no box number to rewrite it to. A rural
    route is deliberately not here: it is a unique delivery point, so
    `RR 1 BOX 8` keeps its key, and measured that is safe – the most
    crowded route-with-box address in the BMF holds 5 EINs

-   `mail_key` the box plus its ZIP (`"PO BOX 1234 59801"`), or `""`
    where the record names no identified box. The complement of the
    address key: blanking a box says two filers are not in one building,
    which is true and is all it says, while two filers collecting mail
    from the *same* box are likely administered by the same people.
    Weight it by `np_mail_freq()` before believing it – one BMF box
    holds 3,626 EINs. See `np_mail_key()`

-   `street_has_box` `TRUE` if the street *carries* a box component,
    whether or not the whole street is one, so `is_po_box` implies
    `street_has_box`. `211 EMMET ST S PO BOX`,
    `300 KENAN CENTER DR CAMPUS BOX` and `ONE HARRISON PLZ BOX 5079` are
    all `TRUE` while `is_po_box` is `FALSE` on each. Filers write the
    street on line 1 and carry the box *number* alone on line 2; this is
    the column that says a bare number from that line may be a box
    rather than a door. It does not claim that it *is* – the street can
    name a suite too (`4347 W NORTHWEST HWY STE 130 BOX`), and that call
    belongs to whoever holds the second line. `street_unit` is not
    changed by it

-   `zip5` five-digit ZIP, leading zeros restored (nested prefix)

-   `zip3` three-digit ZIP prefix / SCF region (nested prefix)

-   `zip9` full `xxxxx-xxxx` ZIP when the +4 is known, else `NA`

The ZIP match hierarchy is the nested prefix family `zip3`
\\(\\subset\\) `zip5` \\(\\subset\\) `zip9`. The +4 add-on (`zip_plus4`)
is an input only, consumed to build `zip9`; it is not a standalone
level.

-   `state_abb` two-letter state code (mapped from a full state name if
    given)

</div>

</div>
