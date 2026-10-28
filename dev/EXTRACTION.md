# Extracting npnormalize from npmatch

**Plan, 2026-10-27.** It moves npmatch's normalizer into its own package, with
every function name and body unchanged, so its signature stays
`v1-3e7b9f9d59bbb19e` and every published matchdb build stays usable.

## Why

npmatch, matchdb and pfmatch all depend on one contract: how a string becomes
a key (`name_key`, `street_key`, the ZIP parts) and how the corpus statistics
are counted.
* matchdb stores those keys for 35 million names and addresses.
* npmatch computes the same keys for every query, as it matches.
* The signature is a hash of the code that makes them, and it is what lets a
  stored artifact refuse a different normalizer.

Today that code lives inside npmatch, so matchdb must import npmatch. As a
result npmatch cannot import matchdb, because each would require the other.
Moving the normalizer into its own package removes the cycle:

```
before:  npmatch  <-  matchdb            (npmatch cannot import matchdb)

after:   npnormalize  <-  npmatch
         npnormalize  <-  matchdb  <-  npmatch    (npmatch may import matchdb)
         npnormalize  <-  networked990             (needs no matching code)
```

Each package then has one job:
* **npnormalize:** turning strings into keys.
* **matchdb:** which organizations exist, and which strings each one carries.
* **npmatch:** how a record finds its organization.

## What moves

The boundary already exists. npmatch's signature registry
(`.np_signature_registry()` in `R/signature.R`) lists exactly what a stored
artifact depends on, and it excludes comparison, scoring, vetoes and tiering.
Everything it lists moves, plus the code that computes the signature:

| from npmatch | objects |
|---|---|
| `R/normalize.R` | 17 rule tables (`.np_legal_suffixes` … `.np_placeholder_tok`); 27 normalize functions (`np_normalize`, `np_name_core`, `np_name_placeholder` and their internals); the corpus statistics (`np_name_freq`, `np_token_idf`, `np_addr_freq`, `.np_addr_key`, `.np_addr_class`); `np_name_rules`; `print.np_addr_freq` |
| `R/block.R` | `np_stopwords`, `.np_tokenize`, `.np_doc_freq` (the index tokenizer the signature covers) |
| `R/signature.R` | all of it. `asNamespace("npmatch")` becomes `asNamespace("npnormalize")`. The exempt list keeps only `np_name_rules`. `detail = TRUE` reports npnormalize's version. |

**Staying in npmatch:**
* the comparators that live in `normalize.R` today (`.np_name_overlap`,
  `.np_partial_ratio`, `.np_contain_overlap`, `.np_collapse_initials`,
  `.np_is_acronymish`), which move to `compare.R`, since they feed
  `np_compare()` and routing;
* query and reference preparation (`np_query`, `np_reference`, the column
  maps);
* blocking and the index (`np_ref_index`, `np_block`);
* everything after.

**Self-contained:** none of the moving code calls anything that stays
(checked with `codetools::findGlobals`). None of it refers to `npmatch::`.

**Exports from npnormalize:**
* the nine functions npmatch exports today: `np_normalize`, `np_name_core`,
  `np_name_placeholder`, `np_name_rules`, `np_stopwords`, `np_name_freq`,
  `np_token_idf`, `np_addr_freq` and `np_normalize_signature`;
* four thin wrappers for the internals npmatch's matching code calls:
  `np_tokenize()`, `np_doc_freq()`, `np_addr_key()` and `np_state_abb()`.

The wrappers are not in the registry, so they do not touch the signature.

## The signature survives: tested

A prototype (`dev/extract-from-npmatch.R`, run against `npmatch@de52bb9`)
copied the 54 objects (726 lines) unchanged into a scratch `npnormalize`:
* **signature:** `v1-3e7b9f9d59bbb19e` in both, and every per-object hash
  identical;
* **`np_normalize()`** on 50,000 rows of the published `active-observed`
  reference: identical output;
* **`np_name_freq()`, `np_token_idf()` and `np_addr_freq()`** over those rows:
  identical.

This works because the signature hashes each listed object's code, keyed by
name, and not the package that holds it. That is why the names and bodies must
not change. One edit during the move and every published build is refused
until matchdb is rebuilt (about 3 hours, plus the uploads).

## Steps

Each step is one PR in one repository, merged in order. **Freeze normalizer
edits in npmatch from step 1 until step 2 merges**, so that the code lives in
exactly one place.

**1. npnormalize 0.1.0** (this repository)
* Generate `R/` with `dev/extract-from-npmatch.R`. It copies each object's
  source text, comments included, from a pinned npmatch commit.
* Adapt `signature.R` (namespace name, exempt list, `detail`), and add the
  four wrappers.
* Write `DESCRIPTION` (Imports: data.table, datasets, stats, stringi,
  stringr, tools, utils; trimmed to what `R CMD check` finds used),
  `NAMESPACE` and roxygen docs. Move each function's documentation with it.
* Tests:
  * move `test-normalize.R` and `test-address-unit.R`, and the normalizer
    parts of `test-address-class.R` and `test-idf.R`;
  * adapt `test-signature.R`, which checks that the registry and exempt list
    split the namespace between them;
  * add a pinned test that `np_normalize_signature()` is
    `v1-3e7b9f9d59bbb19e`, which fails loudly on any accidental edit;
  * add an equivalence test against npmatch, while both exist.
* README, with a short "what the signature is" section, and GitHub Actions
  `R CMD check`.
* **Done when:** the signature is identical; outputs are identical on real
  rows; `R CMD check` is clean.

**2. npmatch: import npnormalize**
* Add `npnormalize` to Imports (with `Remotes:`).
* Delete the moved code, and move the five comparators into `compare.R`.
* Re-export the nine public functions (`importFrom` + `export`), so that
  `npmatch::np_normalize()`, pfmatch, networked990 and existing scripts keep
  working unchanged.
* Internal calls go through npnormalize's exports and wrappers.
* `test-signature.R` becomes "npmatch reports npnormalize's signature".
* **Done when:** npmatch's full test suite passes; `np_normalize_signature()`
  is unchanged; pfmatch's tests pass against it with no edits.

**3. matchdb: import npnormalize, suggest npmatch**
* Change the 9 functions it calls (about 45 call sites in `R/`) from
  `npmatch::` to `npnormalize::`.
* Move npmatch from Imports to Suggests. Package code uses it only in
  `md_reference(build_index = TRUE)` (`np_ref_index()`). There, build the index
  when npmatch is installed; otherwise skip it with a message, and npmatch
  builds it itself when given none. Tests and dev scripts that run
  `np_cascade()` keep npmatch, which is in Suggests.
* Stamps and manifests gain `npnormalize_version` beside `npmatch_version`.
  Old stamps stay readable. The workspace log records npnormalize's version
  and commit.
* **Done when:** matchdb's tests pass; the live bundles, tranches and
  database are still accepted (same signature); a tier compiled from tranches
  is still identical to its bundle.

**4. npmatch: get its reference from matchdb** (a separate decision)
* There is no cycle any more, so npmatch can import matchdb, or suggest it.
* Add `np_registry(source = c("matchdb", "bmf"), tier = …)`, returning the
  reference with `name_freq`, `token_idf`, `ref_index`, clusters and
  address-sharing counts. Model it on pfmatch's
  `pf_reference(source = "matchdb")`.
* Let `np_cascade()` take that object, and use matchdb's address-sharing
  counts rather than recounting from the slice it is given.
* **To decide:** import or suggest. Importing makes every npmatch user
  install matchdb's stack, including DuckDB, a large compiled package.
  Suggesting keeps npmatch light, and falls back to the BMF with a clear
  message.

**5. Downstream, optional**
* networked990 uses only `np_name_core()` and `np_name_rules()`, so it can
  depend on npnormalize alone.
* pfmatch can keep `npmatch::` (it gets the re-exports) or call npnormalize
  for normalization.
* npmatch's re-exports cost nothing to keep. I would keep them rather than
  deprecate them.

## Risks, and what guards each

| risk | guard |
|---|---|
| an edit during the move changes the signature, and every published build is refused | pinned signature test in npnormalize; a normalizer freeze in npmatch during steps 1–2; matchdb's check that the live builds are accepted |
| two copies of the code drift while both exist | the freeze; the equivalence test; step 2 deletes npmatch's copy |
| a caller reaches into npmatch's internals | none found: no `npmatch:::` in matchdb, pfmatch or networked990 |
| moving tests loses coverage | each moved test runs in npnormalize; npmatch keeps the tests that only use `np_normalize()` as setup |
| install order on a fresh machine | `Remotes:` in each DESCRIPTION; npnormalize has no dependents of its own |

## Size

| step | size |
|---|---|
| 1 | about half a day, mostly docs and tests; the code copy is scripted |
| 2 | a few hours |
| 3 | a few hours |
| 4 | its own piece of work, after the decision above |
