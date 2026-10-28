# Changelog

## npnormalize 0.1.0

- First release. npmatch’s normalizer moved into its own package, every
  function name and body unchanged (`dev/extract-from-npmatch.R`, from
  `npmatch@de52bb9`):
  - the rule tables;
  - [`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md),
    [`np_name_core()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_core.md)
    and
    [`np_name_placeholder()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_core.md);
  - the corpus statistics
    ([`np_name_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_name_freq.md),
    [`np_token_idf()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_token_idf.md),
    [`np_addr_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_addr_freq.md),
    [`np_stopwords()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_stopwords.md));
  - the blocking tokenizer;
  - [`np_normalize_signature()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize_signature.md).
- [`np_normalize_signature()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize_signature.md)
  is `v1-3e7b9f9d59bbb19e`, as it was in npmatch, and a test pins it.
- New exported wrappers for the internals npmatch’s matching code calls:
  [`np_tokenize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md),
  [`np_doc_freq()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md),
  [`np_addr_key()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md)
  and
  [`np_state_abb()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md).
  They are not part of the signature.
