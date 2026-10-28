# Changelog

## npnormalize 0.1.1

- New exported
  [`np_unit_id()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_tokenize.md).
  It reduces a suite as
  [`np_normalize()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize.md)
  writes it in `street_unit` (`"STE 300"`, `"# 300"`, `"STE D-2"`) to
  its identifier (`"300"`, `"300"`, `"D2"`), which is the
  `street_unit_id` column.
  - matchdb’s `md_unit_id()` needs a public function for this, because
    it can no longer find npmatch’s internal `.np_unit_id()` once
    npmatch imports this package (step 3 of `dev/EXTRACTION.md`).
  - Like the other four wrappers, it adds nothing of its own, so the
    signature is unchanged:
    [`np_normalize_signature()`](https://nonprofit-open-data-collective.github.io/npnormalize/reference/np_normalize_signature.md)
    is still `v1-3e7b9f9d59bbb19e`.

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
