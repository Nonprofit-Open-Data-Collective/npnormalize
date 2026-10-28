# npnormalize 0.1.0

* First release. npmatch's normalizer moved into its own package, every function
  name and body unchanged (`dev/extract-from-npmatch.R`, from `npmatch@de52bb9`):
  * the rule tables;
  * `np_normalize()`, `np_name_core()` and `np_name_placeholder()`;
  * the corpus statistics (`np_name_freq()`, `np_token_idf()`,
    `np_addr_freq()`, `np_stopwords()`);
  * the blocking tokenizer;
  * `np_normalize_signature()`.
* `np_normalize_signature()` is `v1-3e7b9f9d59bbb19e`, as it was in npmatch, and
  a test pins it.
* New exported wrappers for the internals npmatch's matching code calls:
  `np_tokenize()`, `np_doc_freq()`, `np_addr_key()` and `np_state_abb()`. They
  are not part of the signature.
