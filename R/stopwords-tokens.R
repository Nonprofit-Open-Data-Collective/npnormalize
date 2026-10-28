# Copied unchanged from npmatch@de52bb9 by dev/extract-from-npmatch.R.
# Function names and bodies must not change: the normalizer signature hashes
# them (R/signature.R), and every stored artifact built with it would be
# refused. Comments and roxygen may change; they are not hashed.

#' Blocking stopwords
#'
#' Non-discriminating legal/filler tokens dropped from name-token blocking so
#' blocks stay small and precise. Deliberately conservative (legal forms and
#' function words only) — rely on `max_ref_freq` in [npmatch::np_block()] to prune the
#' remaining corpus-common words data-drivenly rather than hard-coding them.
#'
#' @return A character vector of uppercase stopwords.
#' @export
np_stopwords <- function() {
  c("INC", "INCORPORATED", "CORP", "CORPORATION", "CO", "COMPANY",
    "LLC", "LTD", "LP", "LLP", "PC", "PLLC", "LIMITED",
    "THE", "AND", "OF", "FOR", "A", "AN", "IN", "TO", "AT",
    "FOUNDATION", "FUND", "TRUST", "ASSOCIATION", "ASSN",
    "ORGANIZATION", "ORG")
}

# Tokenize a frame's `token_col` into (row, token) pairs, applying the stopword /
# min-length filter, and (optionally) the adjacent-token concatenation. Returns
# base tokens and concat bigrams separately so a caller can use either. Shared by
# np_block()'s per-side indexing and by np_ref_index() so the two never drift.
.np_tokenize <- function(frame, token_col, stopwords, min_token_len, concat_adjacent) {
  v <- as.character(frame[[token_col]]); v[is.na(v)] <- ""
  toks <- strsplit(v, "\\s+")
  n <- nrow(frame)
  row_all <- rep(seq_len(n), lengths(toks))
  tok_all <- unlist(toks, use.names = FALSE)
  keep <- nchar(tok_all) >= min_token_len & !(tok_all %in% stopwords)
  base <- list(row = row_all[keep], token = tok_all[keep])
  concat <- list(row = integer(0), token = character(0))
  if (isTRUE(concat_adjacent)) {
    filt <- lapply(toks, function(t) t[nchar(t) >= min_token_len & !(t %in% stopwords)])
    bg <- lapply(filt, function(t)
      if (length(t) < 2L) character(0) else paste0(t[-length(t)], t[-1]))
    nb <- lengths(bg)
    concat <- list(row = rep(seq_len(n), nb), token = unlist(bg, use.names = FALSE))
  }
  list(base = base, concat = concat)
}

# Distinct-record document frequency per token. Same values as
# tapply(row, token, function(v) length(unique(v))) but far faster at scale:
# dedup (row, token) via unique.data.table (function dispatch, no `[` DSL), then a
# single table() gives distinct rows per token.
.np_doc_freq <- function(row, token) {
  if (!length(token)) return(stats::setNames(numeric(0), character(0)))
  d <- data.frame(row = row, token = token, stringsAsFactors = FALSE)
  data.table::setDT(d)
  d <- unique(d)
  tb <- table(d$token)
  stats::setNames(as.numeric(tb), names(tb))
}
