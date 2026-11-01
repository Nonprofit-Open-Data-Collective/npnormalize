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

-   `is_po_box` `TRUE` if the street *is* a PO box (any variant), else
    `FALSE`. This is the gate that blanks the address key in
    `np_addr_key()`: a box number is the address, so counting records at
    one counts the box's owners rather than a building's tenants

-   `street_has_box` `TRUE` if the street *carries* a box component,
    whether or not the whole street is one, so `is_po_box` implies
    `street_has_box`. `211 EMMET ST S PO BOX`,
    `300 KENAN CENTER DR CAMPUS BOX` and `PO BOX A` are all `TRUE` while
    `is_po_box` is `FALSE` on each. Filers write the street on line 1
    and carry the box *number* alone on line 2; this is the column that
    says a bare number from that line may be a box rather than a door.
    It does not claim that it *is* – the street can name a suite too
    (`4347 W NORTHWEST HWY STE 130 BOX`), and that call belongs to
    whoever holds the second line. `street_unit` is not changed by it

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
