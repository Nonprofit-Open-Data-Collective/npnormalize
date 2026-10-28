#' Internals npmatch's matching code calls
#'
#' Thin, exported wrappers around four internal helpers, so npmatch's blocking,
#' comparison and geography code can call them without reaching into this
#' package's internals. Most users never call these.
#'
#' * `np_tokenize()` splits a column into tokens for the blocking index, as
#'   [npmatch::np_ref_index()] and [npmatch::np_block()] do.
#' * `np_doc_freq()` counts, for each token, the rows it appears in.
#' * `np_addr_key()` builds the address key [np_addr_freq()] counts on: the
#'   street key and ZIP, blank for a PO box.
#' * `np_state_abb()` maps a state name or code to its two-letter code.
#'
#' They are not part of the normalizer signature: each calls a function that
#' is ([np_normalize_signature()]), and adds nothing of its own.
#'
#' @param frame A data frame holding `token_col`.
#' @param token_col The column to tokenize.
#' @param stopwords Tokens to drop (see [np_stopwords()]).
#' @param min_token_len Shortest token kept.
#' @param concat_adjacent Also index adjacent-token concatenations.
#' @param row,token Parallel vectors: the row each token came from, and the token.
#' @param street_keys,zip5 Street keys and ZIP codes from [np_normalize()].
#' @param state State names or codes.
#' @return `np_tokenize()`: a list of base and concatenated token tables.
#'   `np_doc_freq()`: a named numeric vector of row counts per token.
#'   `np_addr_key()`: a character vector of address keys. `np_state_abb()`: a
#'   character vector of two-letter codes, `NA` where none applies.
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
np_state_abb <- function(state) .np_to_state_abb(state)
