# Package index

## Normalize records

Turn names and addresses into keys that can be matched.

- [`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md)
  : Normalize a query or reference frame
- [`np_name_core()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_core.md)
  [`np_name_placeholder()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_core.md)
  : Exact-lookup name key and placeholder check for raw name strings

## Statistics over the keys

Count how common names, tokens and addresses are, for weighting and
blocking.

- [`np_name_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_freq.md)
  : Name-key frequency table for a reference corpus
- [`np_token_idf()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_token_idf.md)
  : Per-token inverse document frequency for a reference corpus
- [`np_addr_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_addr_freq.md)
  : Address-sharing statistics for a reference corpus

## The signature

Fingerprint the normalizer so stored keys can refuse to load under a
different one.

- [`np_normalize_signature()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize_signature.md)
  : Fingerprint the normalizer

## Building blocks

Tokenizers, stopwords and the rule tables the keys are built from.

- [`np_tokenize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md)
  [`np_doc_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md)
  [`np_addr_key()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md)
  [`np_unit_id()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md)
  [`np_state_abb()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md)
  : Internals npmatch and matchdb call
- [`np_stopwords()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_stopwords.md)
  : Blocking stopwords
- [`np_name_rules()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_rules.md)
  : Name-normalization rule tables

## Package

- [`npnormalize`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/npnormalize-package.md)
  [`npnormalize-package`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/npnormalize-package.md)
  : npnormalize: nonprofit names and addresses as matchable keys
