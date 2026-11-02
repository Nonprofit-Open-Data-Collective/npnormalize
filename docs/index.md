<div id="main" class="col-md-9" role="main">

# npnormalize

<div class="section level1">

npnormalize turns nonprofit names and addresses into keys that can be
matched. It is the normalizer shared by three packages:

-   **npmatch** normalizes each record it matches;
-   **matchdb** stores the same keys for every organization it holds;
-   **pfmatch** normalizes grant recipients before matching them.

A record and the reference it is matched against must be normalized by
the same code. Otherwise matches quietly stop being found, with no
error. This package holds that code in one place, and fingerprints it.

<div class="section level2">

## Install

<div id="cb1" class="sourceCode">

``` r
# install.packages("remotes")
remotes::install_github("Nonprofit-Open-Data-Collective/npnormalize")
```

</div>

</div>

<div class="section level2">

## Use

<div id="cb2" class="sourceCode">

``` r
library(npnormalize)

d <- data.frame(name   = c("The Children's Museum of NH", "St. Luke's Hospital Fdn, Inc."),
                dba    = "",
                street = c("6 Washington Pl Ste 300", "PO Box 1558"),
                unit   = NA,
                zip5   = c("03820", "75201-1234"),
                zip_plus4 = NA,
                state  = c("NH", "Texas"))
np_normalize(d)[, c("name_key", "name_core", "street_key", "street_unit_id", "zip5", "state_abb")]
#>                 name_key                       name_core      street_key street_unit_id  zip5 state_abb
#> 1 CHILDRENS MUSEUM OF NH             CHILDRENS MUSEUM NH 6 WASHINGTON PL            300 03820        NH
#> 2   SAINT LUKES HOSPITAL SAINT LUKES HOSPITAL FOUNDATION     PO BOX 1558           <NA> 75201        TX
```

</div>

**Input columns.** The frame needs the columns `name`, `dba`, `street`,
`unit`, `zip5`, `zip_plus4` and `state`, with `NA` or `""` where a value
is unknown. These are npmatch’s canonical fields, which
`npmatch::np_query()` and `npmatch::np_reference()` produce from any
dataset. `division` is used when present.

**Columns added:** \* name keys: `name_key`, `name_full`, `name_core`,
`dba_key`; \* name features: `name_form`, `name_nums`, `name_ord`,
`name_placeholder`; \* street parts: `street_key`, `street_num`,
`street_name`, `street_type`, `street_unit`, `street_unit_id`,
`is_po_box`, `is_mail_only`, `street_has_box`, `mail_key`; \* ZIP parts:
`zip5`, `zip3`, `zip9`; \* `state_abb`.

`np_name_core()` and `np_name_placeholder()` work on bare name strings,
and `np_extract_unit()` reads the secondary unit out of one free-text
address line (`"123 Main St Ste 300"` -> `"STE 300"`, `NA` where there
is none). `np_is_po_box()`, `np_is_mail_only()` and `np_has_box()`
answer the three box questions on one line — *is this street a box*, *is
it a delivery point with no box number and no building* (general
delivery, military mail), and *does it carry a box component* — so a
consumer deciding whether a bare second-line number is a box number
never needs its own `BOX` regex. For a consumer that cannot call an R
function at all (matchdb’s DuckDB macros), `np_pattern()` hands out the
pattern literals themselves; they are written in the subset R’s engine
and RE2 share, and a test runs them through both. A SQL copy of the
address key needs **both** `np_pattern("pobox")` and
`np_pattern("mailonly")`, since the blank is the union.

`np_addr_key()` and `np_mail_key()` are complements. The address key
answers “same building?”, so it is blank for every mail-delivery address
— leaving one in does not add a wrong row, it makes every box-holder in
a ZIP a co-tenant of every other. The mail key carries what is left: two
organizations collecting mail from the *same* box are likely
administered by the same people. Weight it with `np_mail_freq()` before
believing it — 30,097 of the BMF’s shared boxes hold exactly two EINs,
and the most crowded holds 3,626.

**Statistics over the keys:** \* `np_name_freq()` counts how many
records share each name key. \* `np_token_idf()` weights each name token
by how rare it is. \* `np_addr_freq()` counts the records at each
address and suite, and classifies the address as federated, shared,
building or cluster.

</div>

<div class="section level2">

## The signature

<div id="cb3" class="sourceCode">

``` r
np_normalize_signature()
#> [1] "v1-d49b18cc81ab79fb"
```

</div>

The signature is a hash of the rule tables and functions behind the keys
and statistics, so it changes when their behaviour changes. \* **What it
ignores:** comments and formatting. \* **What it leaves out:** the
matching code in npmatch (comparison, scoring, vetoes), because nothing
it computes is stored.

Anything that stores keys should stamp the signature when it is built,
and refuse to load under a different one. matchdb does this for its
database, bundles and tranches. `np_normalize_signature(detail = TRUE)`
shows which rule table or function moved.

The code was moved here from npmatch unchanged, so the signature is the
one npmatch reported (`dev/EXTRACTION.md`). A test pins the value.
Changing the normalizer is allowed, but it is a deliberate release:
update the pin and rebuild what depends on it.

</div>

</div>

</div>
