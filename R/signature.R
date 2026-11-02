# ---------------------------------------------------------------------------
# Normalizer signature: a fingerprint of everything a caller may precompute.
#
# Downstream packages (matchdb) cache derived columns -- name_key, street_key,
# zip9 -- and corpus statistics built from them. The *query* side is normalized
# at run time by whatever npnormalize is installed. If the normalizer changes after
# an artifact is built, the two sides are normalized differently and recall
# degrades silently: no error, no warning, and a symptom that looks like a data
# problem rather than a version problem.
#
# That is not hypothetical. `.np_strip_joiners()` was rewritten to delete
# apostrophes rather than space them, because the IRS holds "BO'S PLACE" as
# "BOS PLACE" while the old rule produced "BO S PLACE" on the query side. Any
# cached name_key built before that change and read after it is wrong.
#
# The signature exists so a cache can refuse to be used against a normalizer it
# was not built with.
# ---------------------------------------------------------------------------

# What the signature covers. Order within the registry does not matter (the
# per-component hashes are sorted by name before combining), but membership very
# much does -- see .np_signature_exempt below for the counterpart list.
#
# A pattern COMPOSED from pieces is registered as the composed value only
# (.np_pobox_pat, not .np_box_head and .np_box_id). The pieces are inputs to a
# value that is already hashed, so editing one still moves the signature, while
# a refactor that rearranges the pieces without changing the pattern does not --
# the same property that makes the registry strip comments before hashing.
.np_signature_registry <- function() {
  list(
    # --- rule tables consulted by np_normalize() -----------------------------
    tables = c(
      ".np_legal_suffixes", ".np_abbrev", ".np_street_types",
      ".np_generation", ".np_ordinals", ".np_gen_rank", ".np_directions",
      ".np_street_type_set", ".np_state_abbr", ".np_state_codes",
      ".np_unit_pat", ".np_pobox_pat", ".np_mailonly_pat", ".np_box_pat",
      ".np_unit_id_strip", ".np_hyphen_house", ".np_split_words",
      ".np_special_letters", ".np_unit_designators", ".np_unit_rank",
      ".np_core_stop", ".np_placeholder_re", ".np_placeholder_tok"
    ),
    # --- functions producing the per-row derived columns --------------------
    normalize = c(
      "np_normalize",
      ".np_tokens", ".np_replace_tokens", ".np_strip_joiners",
      ".np_map_special", ".np_basic_clean", ".np_fold_split",
      ".np_join_house_number",
      ".np_extract_generation", ".np_extract_numbers", ".np_extract_ordinals",
      ".np_extract_direction", ".np_extract_form", ".np_canon_form",
      ".np_strip_lead_the", ".np_strip_suffix",
      ".np_is_pobox", ".np_is_mailonly", ".np_has_box", ".np_box_identifier",
      ".np_extract_unit", ".np_pick_unit", ".np_norm_unit", ".np_unit_id",
      ".np_street_key", ".np_mail_key",
      ".np_parse_street", ".np_parse_zip", ".np_to_state_abb",
      ".np_name_core", ".np_is_placeholder", ".np_clean_name",
      "np_name_core", "np_name_placeholder"
    ),
    # --- corpus statistics shipped alongside a compiled reference -----------
    corpus = c("np_stopwords", "np_name_freq", "np_token_idf",
               "np_addr_freq", ".np_addr_key", ".np_addr_class",
               "np_mail_freq"),
    # --- the blocking index a caller may also cache -------------------------
    index = c(".np_tokenize", ".np_doc_freq")
  )
}

# Deliberately NOT covered: comparison, scoring, veto, selection, tiering. None
# of it is precomputed, so a change there cannot invalidate a cached artifact,
# and folding it in would fire the check on edits that do not matter -- which is
# how a staleness check gets ignored. Listed explicitly (rather than left
# implicit) so `test-signature.R` can assert the two sets partition the
# normalize-path internals, and a newly added rule table fails the test until
# someone classifies it.
.np_signature_exempt <- function() {
  # the comparators that sat beside the normalizer stayed in npmatch
  c("np_name_rules",   # an accessor: returns the registered tables, derives nothing
    # The pieces .np_pobox_pat and .np_mailonly_pat are composed from.
    # Registering the composed patterns already hashes their contents, and
    # leaving them out is what lets the vocabulary be rearranged without moving
    # the signature. Exempt, not forgotten -- the completeness test is why this
    # list exists.
    ".np_box_head", ".np_box_id", ".np_mail_head")
}

.np_sig_md5 <- function(x) {
  s <- enc2utf8(paste(x, collapse = "\n"))
  f <- tempfile("npsig")
  on.exit(unlink(f), add = TRUE)
  writeBin(charToRaw(s), f)
  unname(tools::md5sum(f))
}

# Canonical text for one registered object.
#
# Functions are deparsed after utils::removeSource(), which strips srcref and
# with it every comment. That is the point: reformatting or re-commenting must
# not invalidate a cache, while a change to the logic must. `control` is pinned
# rather than left to the default so deparse output does not drift between R
# versions.
.np_sig_text <- function(name, envir = asNamespace("npnormalize")) {
  obj <- get(name, envir = envir)
  if (is.function(obj)) {
    paste(deparse(utils::removeSource(obj),
                  width.cutoff = 500L,
                  control = c("keepInteger", "keepNA")),
          collapse = "\n")
  } else {
    nm <- names(obj)
    if (is.null(nm)) nm <- rep("", length(obj))
    paste(nm, as.character(obj), sep = "\t", collapse = "\n")
  }
}

# Every signature this package has published, and the one npmatch published
# before the normalizer moved out of it. The history was prose -- a comment
# beside the pin in tests/testthat/test-signature.R -- which a person can read
# and a script cannot. Consumers stamp provenance headers from
# packageVersion(), which dates the CURRENT signature and is no help for a
# historical one: matchdb and pfmatch each had to date v1-59c6e84c5f38e9f5 by
# hand, from NEWS, which is an inference in a provenance header.
#
# Not called a registry: .np_signature_registry() already means the list of
# objects that get hashed, and two things called a registry in one file would
# be worse than a longer name.
#
# The pre-split rows are here ON PURPOSE rather than omitted. A table that
# returned nothing for them would leave a caller unable to tell "not an
# npnormalize signature" from "npnormalize signature I have not recorded", and
# the first is a fact worth stating. Their npmatch version was never written
# down anywhere I can find, so `version` is NA and `summary` says where the
# value is cited -- undated, not guessed.
.np_signature_log <- data.frame(
  signature = c(
    "v1-421e1e2a6afb024e", "v1-6dcb298522cc5118", "v1-b42811fe6601afe6",
    "v1-3e7b9f9d59bbb19e", "v1-6d90b52d8b781673", "v1-592912060053c4c3",
    "v1-1179714ce1e9d31f", "v1-533f186c123357cf", "v1-d49b18cc81ab79fb",
    "v1-59c6e84c5f38e9f5", "v1-5e901add4a04a5d6"),
  package = c(rep("npmatch", 3L), rep("npnormalize", 8L)),
  version = c(
    "0.0.0.9000", "0.1.0.9000", NA_character_,
    "0.1.0", "0.1.2", "0.1.3", "0.1.4", "0.1.5", "0.1.6", "0.1.7", "0.1.8"),
  summary = c(
    "before the split; npmatch@f14f1d9, recorded beside this value in pfmatch dev/BASELINE-2026-08/environment.txt, measured 2026-08-22 (the commit's own date); reported, not reproduced here",
    "before the split; npmatch@ddfd967, recorded beside this value in pfmatch dev/BENCH-MD-REFERENCE.log, measured 2026-10-23 (the commit's own date); reported, not reproduced here",
    "before the split; cited in matchdb dev/verify/build-baseline-2026-10.R as npmatch's value after v1-421e1e2a6afb024e, with no commit recorded anywhere I can find -- undated on purpose",
    "the value npmatch gave before the move; unchanged by it, and 0.1.1 reports it too",
    "BUILDING became a unit designator (#7)",
    "a line naming several units keeps the most specific one, and the house number is a whole token",
    "street_has_box added and the box gate anchored (#9)",
    "a lettered box is a box, and one helper reads the box identifier (#12)",
    "the long-tail box spellings, is_mail_only and mail_key (#13)",
    "a hyphenated house number is joined, and eleven FOUNDATION spellings fold (#16, #17)",
    "the join stops closing up a lone compass letter (#16); 0.1.9 reports it too, having changed no rule"),
  stringsAsFactors = FALSE
)

#' Which release produced a normalizer signature
#'
#' [np_normalize_signature()] returns an opaque value, which is what makes it a
#' good fingerprint and a poor label: it says *that* two artifacts disagree,
#' never which is newer. This dates every signature the package has published,
#' so a script writing a provenance header can stamp the release beside the
#' signature instead of a person looking it up in `NEWS.md`.
#'
#' The three oldest rows are npmatch's, from before the normalizer moved into
#' this package. They are listed so that an unrecognized value can be told from
#' a recognized pre-split one.
#'
#' **Those rows are weaker evidence than the rest, and knowingly so.** An
#' npnormalize row is authoritative: this package computed the value, and a
#' test asserts the installed signature appears in the table under the
#' installed release. An npmatch row is *reported* — read out of a consumer's
#' run-time record that happened to log the signature beside the commit, and
#' not reproduced here, because doing that would mean installing a pre-split
#' npmatch. `summary` names the record in each case so the reader can judge it.
#' One of the three has no commit recorded anywhere, so its `version` stays
#' `NA`: undated, rather than inferred from its neighbours.
#'
#' # A signature does not determine a release
#'
#' A release that changes no rule reports its predecessor's value: 0.1.0 and
#' 0.1.1 both report `v1-3e7b9f9d59bbb19e`. So this answers *which release
#' produced this value* — meaning the earliest that could have — and not *which
#' release is installed*. A stamped artifact wants **both**: the signature, so a
#' reader can tell whether its keys are comparable with theirs, and
#' [utils::packageVersion()] at build time, so they can tell what was running.
#' Neither determines the other, and a header carrying only one of them invites
#' the reader to infer the other.
#'
#' @param signature Optionally one or more signature strings to look up. A
#'   value that is not listed returns no rows — it is not an error, and it is
#'   not the same as a listed row with an `NA` version.
#' @return A data frame of `signature`, `package`, `version` and `summary`, in
#'   publication order. `version` is the release that *introduced* the
#'   signature; a later release that reports the same value unchanged is named
#'   in `summary` rather than given a row of its own, so one signature is one
#'   row and the column stays usable for comparison.
#' @seealso [np_normalize_signature()]
#' @examples
#' np_signature_history(np_normalize_signature())
#'
#' # the whole history, oldest first
#' np_signature_history()[, c("signature", "package", "version")]
#' @export
np_signature_history <- function(signature = NULL) {
  out <- .np_signature_log
  if (!is.null(signature)) out <- out[out$signature %in% signature, , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Fingerprint the normalizer
#'
#' A hash over everything a caller may legitimately **precompute and cache**: the
#' rule tables and functions behind [np_normalize()], the corpus statistics
#' ([np_name_freq()], [np_token_idf()], [np_stopwords()]), and the tokenizer
#' behind [npmatch::np_ref_index()].
#'
#' # Why
#'
#' A cached reference stores derived columns — `name_key`, `street_key`, `zip9`
#' — while the query side is normalized at run time by whatever npnormalize is
#' installed. Change the normalizer between those two moments and the sides are
#' normalized differently: matches quietly stop being found, with no error and a
#' symptom that reads as a data problem. Stamp this value into an artifact when
#' you build it, compare on load, and **error** on mismatch.
#'
#' # What is covered
#'
#' Only what is precomputable. Comparison, scoring, vetoes, selection and
#' tiering are excluded by design — none of them is cached, so a change there
#' must not invalidate an artifact. A signature that fires on unrelated edits is
#' one people learn to ignore.
#'
#' Function bodies are compared after [utils::removeSource()], so **comments and
#' reformatting leave the signature unchanged while logic changes move it**.
#'
#' # Stability
#'
#' The returned string carries a `v1-` format prefix. If a later npnormalize changes
#' *what* is hashed, the prefix changes too, so that is distinguishable from a
#' change to the normalizer itself.
#'
#' @param detail If `TRUE`, also return the per-component hashes, so a mismatch
#'   can be localized to the rule table or function that moved. Default `FALSE`.
#' @return A signature string such as `"v1-a1b2c3d4e5f60718"`. With
#'   `detail = TRUE`, an `np_signature` object carrying that string, the
#'   per-component hashes, and the npnormalize version.
#' @seealso [np_normalize()]
#' @examples
#' sig <- np_normalize_signature()
#' sig
#'
#' # which components make it up
#' names(np_normalize_signature(detail = TRUE)$components)
#' @export
np_normalize_signature <- function(detail = FALSE) {
  out <- .np_signature_from(asNamespace("npnormalize"))
  if (!detail) return(out$signature)
  structure(c(out,
              list(npnormalize_version = as.character(utils::packageVersion("npnormalize")))),
            class = "np_signature")
}

# The computation, against an arbitrary environment. Split out so a historical
# check can source an older R/normalize.R into a bare environment and get a
# comparable value -- see dev/probe-signature-history.R, which is what actually
# demonstrates the "moves on logic, not on comments" property against real
# commits rather than synthetic edits.
.np_signature_from <- function(envir) {
  names_all <- sort(unique(unlist(.np_signature_registry(), use.names = FALSE)))
  present <- vapply(names_all, exists, logical(1), envir = envir, inherits = FALSE)
  comp <- vapply(names_all[present],
                 function(n) .np_sig_md5(.np_sig_text(n, envir)), character(1))
  # combine the per-component hashes, not the raw text: a component's hash is
  # then independently reportable and the overall value is order-stable.
  overall <- .np_sig_md5(paste(names(comp), comp, sep = "=", collapse = "\n"))
  list(signature = paste0("v1-", substr(overall, 1L, 16L)),
       components = comp,
       missing = names_all[!present])
}

#' @export
print.np_signature <- function(x, ...) {
  cat("<np_signature>", x$signature, "\n")
  cat("  npnormalize", x$npnormalize_version, "|", length(x$components), "components\n")
  invisible(x)
}
