#' Internals npmatch and matchdb call
#'
#' Thin, exported wrappers around six internal helpers. npmatch's blocking,
#' comparison and geography code, and matchdb's place keys, call these instead
#' of reaching into this package's internals. Most users never call them.
#'
#' * `np_tokenize()` splits a column into tokens for the blocking index, as
#'   [npmatch::np_ref_index()] and [npmatch::np_block()] do.
#' * `np_doc_freq()` counts, for each token, the rows it appears in.
#' * `np_addr_key()` builds the address key [np_addr_freq()] counts on: the
#'   street key and ZIP, blank for a PO box.
#' * `np_extract_unit()` reads the secondary unit out of one free-text address
#'   line, exactly as [np_normalize()] fills `street_unit`: `"STE 300"`,
#'   `"FL 2"`, `"# 12"`, or `NA` where the line names no unit. This is the
#'   single-vector entry point onto the designator gate, for a caller holding a
#'   free-text line (a Form 990-PF address line 2, say) rather than a frame.
#' * `np_unit_id()` reduces a suite as written to its identifier: the
#'   designator and separators are dropped, so `"STE 300"`, `"Suite 300"` and
#'   `"# 300"` all give `"300"`, and `"STE D-2"` gives `"D2"`. This is the
#'   `street_unit_id` column [np_normalize()] adds, computed from
#'   `street_unit`.
#'
#'   It is gated by the same designator pattern as `np_extract_unit()`, so a
#'   line that names no unit returns `NA` rather than a confident reduction of
#'   whatever was passed: `"PO BOX 1367"`, `"114 HIGH ST"`, `"LAS VEGAS"` and
#'   `"400891"` are all `NA`. A bare identifier with no designator (`"300"`) is
#'   `NA` too, because a digit string on its own is as often a box number or a
#'   record counter as a door; pass a dedicated unit column as
#'   `np_extract_unit()`'s `unit` argument, where a bare value is accepted
#'   because the column itself says what it is.
#' * `np_state_abb()` maps a state name or code to its two-letter code.
#'
#' They are not part of the normalizer signature: each only calls functions
#' that are ([np_normalize_signature()]), and adds nothing of its own.
#'
#' @param frame A data frame holding `token_col`.
#' @param token_col The column to tokenize.
#' @param stopwords Tokens to drop (see [np_stopwords()]).
#' @param min_token_len Shortest token kept.
#' @param concat_adjacent Also index adjacent-token concatenations.
#' @param row,token Parallel vectors: the row each token came from, and the token.
#' @param street_keys,zip5 Street keys and ZIP codes from [np_normalize()].
#' @param street A free-text street or address line, as [np_normalize()] takes
#'   it in `street`.
#' @param unit For `np_extract_unit()`, the canonical second address line, read
#'   only where `street` carries no unit; a bare value there is accepted
#'   (`"300"` gives `"# 300"`), since a dedicated unit column needs no
#'   designator to say what it is. For `np_unit_id()`, a suite as
#'   [np_normalize()] writes it in `street_unit` (`"STE 300"`, `"FL 2"`,
#'   `"# 12"`).
#' @param state State names or codes.
#' @return `np_tokenize()`: a list of base and concatenated token tables.
#'   `np_doc_freq()`: a named numeric vector of row counts per token.
#'   `np_addr_key()`: a character vector of address keys.
#'   `np_extract_unit()`: a character vector of canonical units, `NA` where the
#'   address names none. `np_unit_id()`: a
#'   character vector of suite identifiers, `NA` where there is none.
#'   `np_state_abb()`: a character vector of two-letter codes, `NA` where none
#'   applies.
#' @keywords internal
#' @export
np_tokenize <- function(frame, token_col, stopwords, min_token_len, concat_adjacent) {
  .np_tokenize(frame, token_col, stopwords, min_token_len, concat_adjacent)
}

#' @rdname np_tokenize
#' @export
np_doc_freq <- function(row, token) .np_doc_freq(row, token)

#' @rdname np_tokenize
#' @export
np_addr_key <- function(street_keys, zip5 = NULL) .np_addr_key(street_keys, zip5)

#' @rdname np_tokenize
#' @export
np_extract_unit <- function(street, unit = NULL) .np_extract_unit(street, unit)

#' @rdname np_tokenize
#' @export
np_unit_id <- function(unit) .np_unit_id(.np_extract_unit(unit))

#' @rdname np_tokenize
#' @export
np_state_abb <- function(state) .np_to_state_abb(state)
