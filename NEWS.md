# npnormalize 0.1.1

* New exported `np_unit_id()`. It reduces a suite as `np_normalize()` writes it
  in `street_unit` (`"STE 300"`, `"# 300"`, `"STE D-2"`) to its identifier
  (`"300"`, `"300"`, `"D2"`), which is the `street_unit_id` column.
  * matchdb's `md_unit_id()` needs a public function for this, because it can
    no longer find npmatch's internal `.np_unit_id()` once npmatch imports this
    package (step 3 of `dev/EXTRACTION.md`).
  * Like the other four wrappers, it adds nothing of its own, so the signature
    is unchanged: `np_normalize_signature()` is still `v1-3e7b9f9d59bbb19e`.

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
