#' npnormalize: nonprofit names and addresses as matchable keys
#'
#' The normalizer shared by npmatch, matchdb and the packages built on them.
#' [np_normalize()] turns an organization's name and address into keys
#' (`name_key`, `name_core`, `street_key`, the ZIP parts and more), and
#' [np_name_freq()], [np_token_idf()] and [np_addr_freq()] count statistics
#' over those keys.
#'
#' A record and the reference it is matched against have to be normalized by
#' the same code, or matches quietly stop being found.
#' [np_normalize_signature()] is a hash of that code. matchdb stamps it into
#' everything it publishes, and refuses to use a stored artifact under a
#' different normalizer.
#'
#' This code was moved out of npmatch unchanged (`dev/EXTRACTION.md`), so the
#' signature it gives is the one npmatch gave.
#'
#' @keywords internal
"_PACKAGE"

# The state tables in R/normalize.R are built from datasets::state.abb and
# state.name when the package is built, which R CMD check does not count as a
# use of the 'datasets' import. A dataset cannot be named in importFrom(), so
# this records the use. It is not part of the normalizer or its signature.
.npnormalize_uses_datasets <- function() datasets::state.abb
