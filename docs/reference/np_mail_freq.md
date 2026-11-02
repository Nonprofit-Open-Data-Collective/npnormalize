<div id="main" class="col-md-9" role="main">

# Mail-key frequency table for a reference corpus

<div class="ref-description section level2">

Counts how many reference records share each exact `mail_key` (box +
ZIP). This is what makes a shared box *interpretable* rather than merely
true, and it is not an optional refinement — measured over the
3,687,435-row unified BMF, the key separates two populations that want
opposite treatment:

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
np_mail_freq(mail_keys)
```

</div>

</div>

<div class="section level2">

## Arguments

-   mail_keys:

    Character vector of mail keys (reference `mail_key`), as built by
    `np_mail_key()`. Empty strings are dropped, so records that name no
    box do not all pile onto one entry.

</div>

<div class="section level2">

## Value

A named integer vector mapping `mail_key` -> record count.

</div>

<div class="section level2">

## Details

-   **A box shared by two or three filers** is the signal worth having:
    an organization and its foundation, a parent and its chapter, a
    small group of charities run out of one accountant's office. 30,097
    of the 36,910 shared boxes hold exactly two EINs and 3,829 hold
    three.

-   **A box shared by hundreds** is a service bureau and is evidence of
    nothing. 678 boxes hold ten or more EINs, and the most crowded —
    `PO BOX 653067` in ZIP 75265 — holds **3,626**. Treating that as
    common administration would link 3,626 unrelated organizations to
    each other.

So read `mail_key` as evidence only below a threshold, the same way
`np_addr_freq()`'s `share_min` gates an address. Overall: 496,830
distinct mail keys, 7.43% of them shared, and 20.79% of box-holding EINs
on a shared box.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`np_mail_key()`, `np_addr_freq()`

</div>

</div>

</div>
