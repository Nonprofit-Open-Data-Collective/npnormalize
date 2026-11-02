<div id="main" class="col-md-9" role="main">

# Internals npmatch and matchdb call

<div class="ref-description section level2">

Thin, exported wrappers around this package's internal helpers.
npmatch's blocking, comparison and geography code, and matchdb's place
keys, call these instead of reaching into this package's internals. Most
users never call them.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_tokenize(frame, token_col, stopwords, min_token_len, concat_adjacent)

np_doc_freq(row, token)

np_addr_key(street_keys, zip5 = NULL)

np_mail_key(street_keys, zip5 = NULL)

np_extract_unit(street, unit = NULL)

np_unit_id(unit)

np_state_abb(state)

np_is_po_box(street)

np_is_mail_only(street)

np_has_box(street)

np_pattern(which = c("pobox", "mailonly", "box", "unit_id"))
```

</div>

</div>

<div class="section level2">

## Arguments

-   frame:

    A data frame holding `token_col`.

-   token_col:

    The column to tokenize.

-   stopwords:

    Tokens to drop (see `np_stopwords()`).

-   min_token_len:

    Shortest token kept.

-   concat_adjacent:

    Also index adjacent-token concatenations.

-   row, token:

    Parallel vectors: the row each token came from, and the token.

-   street_keys, zip5:

    Street keys and ZIP codes from `np_normalize()`.

-   street:

    A free-text street or address line, as `np_normalize()` takes it in
    `street`.

-   unit:

    For `np_extract_unit()`, the canonical second address line, read
    only where `street` carries no unit; a bare value there is accepted
    (`"300"` gives `"# 300"`), since a dedicated unit column needs no
    designator to say what it is. For `np_unit_id()`, a suite as
    `np_normalize()` writes it in `street_unit` (`"STE 300"`, `"FL 2"`,
    `"# 12"`).

-   state:

    State names or codes.

-   which:

    For `np_pattern()`, which literal to return: `"pobox"` (the
    `is_po_box` gate, anchored at the head of the key), `"mailonly"`
    (the `is_mail_only` gate, the second half of the `np_addr_key()`
    blank), `"box"` (the `street_has_box` tail) or `"unit_id"` (the
    designator `np_unit_id()` strips). A SQL copy of the address key
    needs **both** `"pobox"` and `"mailonly"`; taking only the first
    leaves the macro narrower than `np_addr_key()`.

</div>

<div class="section level2">

## Value

`np_tokenize()`: a list of base and concatenated token tables.
`np_doc_freq()`: a named numeric vector of row counts per token.
`np_addr_key()`: a character vector of address keys. `np_mail_key()`: a
character vector of box keys, `""` where the record names no identified
box. `np_extract_unit()`: a character vector of canonical units, `NA`
where the address names none. `np_unit_id()`: a character vector of
suite identifiers, `NA` where there is none. `np_state_abb()`: a
character vector of two-letter codes, `NA` where none applies.
`np_is_po_box()`, `np_is_mail_only()` and `np_has_box()`: logical
vectors, one value per input line. `np_pattern()`: one regex string.

</div>

<div class="section level2">

## Details

-   `np_tokenize()` splits a column into tokens for the blocking index,
    as `npmatch::np_ref_index()` and `npmatch::np_block()` do.

-   `np_doc_freq()` counts, for each token, the rows it appears in.

-   `np_addr_key()` builds the address key `np_addr_freq()` counts on:
    the street key and ZIP, blank for any mail-delivery address — a box,
    general delivery, or military mail. The key answers "same
    building?", so leaving one in does not add a wrong row, it builds a
    cluster of every box-holder in the ZIP.

-   `np_mail_key()` builds its complement: the box and ZIP, blank for
    everything else, including the mail-only designators that have no
    identifier. A shared box is evidence of shared administration rather
    than of a shared building — gate it on `np_mail_freq()`, because one
    BMF box holds 3,626 EINs.

-   `np_extract_unit()` reads the secondary unit out of one free-text
    address line, exactly as `np_normalize()` fills `street_unit`:
    `"STE 300"`, `"FL 2"`, `"# 12"`, or `NA` where the line names no
    unit. This is the single-vector entry point onto the designator
    gate, for a caller holding a free-text line (a Form 990-PF address
    line 2, say) rather than a frame.

-   `np_unit_id()` reduces a suite as written to its identifier: the
    designator and separators are dropped, so `"STE 300"`, `"Suite 300"`
    and `"# 300"` all give `"300"`, and `"STE D-2"` gives `"D2"`. This
    is the `street_unit_id` column `np_normalize()` adds, computed from
    `street_unit`.

    It is gated by the same designator pattern as `np_extract_unit()`,
    so a line that names no unit returns `NA` rather than a confident
    reduction of whatever was passed: `"PO BOX 1367"`, `"114 HIGH ST"`,
    `"LAS VEGAS"` and `"400891"` are all `NA`. A bare identifier with no
    designator (`"300"`) is `NA` too, because a digit string on its own
    is as often a box number or a record counter as a door; pass a
    dedicated unit column as `np_extract_unit()`'s `unit` argument,
    where a bare value is accepted because the column itself says what
    it is.

-   `np_state_abb()` maps a state name or code to its two-letter code.

-   `np_is_po_box()`, `np_is_mail_only()` and `np_has_box()` answer the
    three box questions for a caller holding one free-text line rather
    than a frame: *is this street a box* (the `is_po_box` column), *is
    it a mail-delivery address with no box number and no building* (the
    `is_mail_only` column — general delivery and military mail; the two
    together are the gate that blanks `np_addr_key()`), and *does it
    carry a box component* (the `street_has_box` column, which is also
    TRUE where a street ends in the box word and the number is carried
    on line 2). They exist so that a consumer deciding whether a bare
    identifier is a box number calls this package instead of keeping its
    own `BOX` regex: pfmatch's did not anchor, and an unanchored `BOX`
    claims 127 BMF rows whose street is merely *named* for a box
    (`BOX ELDER ST`, `BOX SPGS RD`).

-   `np_pattern()` hands out the pattern literals themselves, for a
    consumer that cannot call an R function at all. matchdb is the case:
    DuckDB's R client registers data frames, not scalar UDFs, so
    `md_place_key()` has to be a SQL macro over a regex string. Taking
    the string from here keeps the macro and `np_addr_key()` from
    drifting apart, which is why the patterns are written in the subset
    R's engine and RE2 share – no lookaround, no `\\d`. `np_pattern()`
    is not a licence to reimplement: prefer the functions above wherever
    R can be called.

They are not part of the normalizer signature: each only calls functions
that are (`np_normalize_signature()`), and adds nothing of its own.

</div>

</div>
