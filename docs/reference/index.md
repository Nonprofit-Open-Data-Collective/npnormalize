<div id="main" class="col-md-9" role="main">

# Package index

<div class="section level2">

## Normalize records

<div class="section-desc">

Turn names and addresses into keys that can be matched.

</div>

</div>

<div class="section level2">

-   `np_normalize()` : Normalize a query or reference frame
-   `np_name_core()` `np_name_placeholder()` : Exact-lookup name key and
    placeholder check for raw name strings

</div>

<div class="section level2">

## Statistics over the keys

<div class="section-desc">

Count how common names, tokens and addresses are, for weighting and
blocking.

</div>

</div>

<div class="section level2">

-   `np_name_freq()` : Name-key frequency table for a reference corpus
-   `np_token_idf()` : Per-token inverse document frequency for a
    reference corpus
-   `np_addr_freq()` : Address-sharing statistics for a reference corpus

</div>

<div class="section level2">

## The signature

<div class="section-desc">

Fingerprint the normalizer so stored keys can refuse to load under a
different one.

</div>

</div>

<div class="section level2">

-   `np_normalize_signature()` : Fingerprint the normalizer

</div>

<div class="section level2">

## Building blocks

<div class="section-desc">

Tokenizers, stopwords and the rule tables the keys are built from.

</div>

</div>

<div class="section level2">

-   `np_tokenize()` `np_doc_freq()` `np_addr_key()` `np_extract_unit()`
    `np_unit_id()` `np_state_abb()` : Internals npmatch and matchdb call
-   `np_stopwords()` : Blocking stopwords
-   `np_name_rules()` : Name-normalization rule tables

</div>

<div class="section level2">

## Package

</div>

<div class="section level2">

-   `npnormalize` `npnormalize-package` : npnormalize: nonprofit names
    and addresses as matchable keys

</div>

</div>
