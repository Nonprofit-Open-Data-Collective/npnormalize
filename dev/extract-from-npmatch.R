#!/usr/bin/env Rscript
# Copy npmatch's normalizer into this package, unchanged (dev/EXTRACTION.md).
#
#   Rscript dev/extract-from-npmatch.R [npmatch dir] [reference.parquet]
#
# Copies every object the normalizer signature covers, plus np_name_rules and
# print.np_addr_freq, from npmatch's R/normalize.R and R/block.R into
# R/normalize.R and R/stopwords-tokens.R: each object's source text exactly as
# written, with the comment block (roxygen included) directly above it. Copies
# R/signature.R pointed at this namespace. In roxygen lines only, a link to a
# function that stays in npmatch becomes [npmatch::f()].
#
# Then loads the result in a scratch package and checks: the same signature as
# npmatch, the same per-object hashes, and (given a reference parquet) identical
# np_normalize() and corpus statistics on 50,000 of its rows. Comments and
# roxygen are not part of the signature, so none of the edits above can move
# it; the check proves that. Run from this repository's root.
a <- commandArgs(TRUE)
np_dir <- if (length(a) >= 1) a[1] else "../npmatch"
ref_pq <- if (length(a) >= 2) a[2] else NA
stopifnot(file.exists(file.path(np_dir, "R", "signature.R")))
suppressMessages(pkgload::load_all(np_dir, quiet = TRUE, export_all = TRUE))
np_sha <- system2("git", c("-C", shQuote(np_dir), "rev-parse", "--short", "HEAD"), stdout = TRUE)
cat("npmatch at", np_sha, "\n")

reg <- unlist(npmatch:::.np_signature_registry(), use.names = FALSE)
move <- c(reg, "np_name_rules", "print.np_addr_freq")
# the exported functions this package defines, so links to them stay local
local_fns <- c(move, "np_normalize_signature", "np_tokenize", "np_doc_freq",
               "np_addr_key", "np_state_abb")

# the top-level assignments to `names` in `file`: source text, comments above included
take <- function(file, names) {
  path <- file.path(np_dir, "R", file)
  lines <- readLines(path, warn = FALSE)
  ex <- parse(path, keep.source = TRUE)
  sr <- attr(ex, "srcref"); got <- character(); txt <- character()
  for (i in seq_along(ex)) {
    e <- ex[[i]]
    if (is.call(e) && as.character(e[[1]]) %in% c("<-", "=") && is.name(e[[2]]) &&
        as.character(e[[2]]) %in% names) {
      first <- sr[[i]][1]; last <- sr[[i]][3]
      top <- first
      while (top > 1 && grepl("^\\s*#", lines[top - 1])) top <- top - 1
      got <- c(got, as.character(e[[2]]))
      txt <- c(txt, paste(lines[top:last], collapse = "\n"))
    }
  }
  list(got = got, txt = txt)
}

# in roxygen lines, [f()] for a function not defined here -> [npmatch::f()]
fix_links <- function(x) {
  l <- strsplit(x, "\n", fixed = TRUE)[[1]]
  rox <- grepl("^\\s*#'", l)
  l[rox] <- vapply(l[rox], function(s) {
    m <- gregexpr("\\[(np_[A-Za-z0-9_]+)\\(\\)\\]", s)
    hits <- regmatches(s, m)[[1]]
    for (h in unique(hits)) {
      f <- sub("^\\[(np_[A-Za-z0-9_]+)\\(\\)\\]$", "\\1", h)
      if (!f %in% local_fns) s <- gsub(h, sprintf("[npmatch::%s()]", f), s, fixed = TRUE)
    }
    s
  }, "", USE.NAMES = FALSE)
  paste(l, collapse = "\n")
}

a1 <- take("normalize.R", move); a2 <- take("block.R", move)
missing <- setdiff(move, c(a1$got, a2$got))
if (length(missing)) stop("not found in npmatch: ", paste(missing, collapse = ", "))

dir.create("R", showWarnings = FALSE)
hdr <- sprintf(paste0(
  "# Copied unchanged from npmatch@%s by dev/extract-from-npmatch.R.\n",
  "# Function names and bodies must not change: the normalizer signature hashes\n",
  "# them (R/signature.R), and every stored artifact built with it would be\n",
  "# refused. Comments and roxygen may change; they are not hashed.\n"), np_sha)
writeLines(c(hdr, fix_links(paste(a1$txt, collapse = "\n\n"))), "R/normalize.R")
writeLines(c(hdr, fix_links(paste(a2$txt, collapse = "\n\n"))), "R/stopwords-tokens.R")

# signature.R: this namespace, this package's version, and the docs to match.
# None of these lines are in the registry, so none of them is hashed.
sig <- paste(readLines(file.path(np_dir, "R", "signature.R")), collapse = "\n")
from <- c(
  'asNamespace("npmatch")',
  'npmatch_version = as.character(utils::packageVersion("npmatch"))',
  'cat("  npmatch", x$npmatch_version',
  "per-component hashes, and the npmatch version.",
  "by whatever npmatch is",
  "If a later npmatch changes",
  # the comparators stayed in npmatch; np_name_rules is the one exempt object here
  paste0('  c(".np_collapse_initials", ".np_is_acronymish", ".np_name_overlap",\n',
         '    ".np_contain_overlap",\n',
         '    ".np_partial_ratio",  # substring comparator; feeds np_compare, precomputes nothing\n',
         '    "np_name_rules")   # an accessor: returns the registered tables, derives nothing'))
to <- c(
  'asNamespace("npnormalize")',
  'npnormalize_version = as.character(utils::packageVersion("npnormalize"))',
  'cat("  npnormalize", x$npnormalize_version',
  "per-component hashes, and the npnormalize version.",
  "by whatever npnormalize is",
  "If a later npnormalize changes",
  paste0('  # the comparators that sat beside the normalizer stayed in npmatch\n',
         '  c("np_name_rules")   # an accessor: returns the registered tables, derives nothing'))
for (i in seq_along(from)) {
  if (!grepl(from[i], sig, fixed = TRUE)) stop("signature.R no longer contains: ", substr(from[i], 1, 60))
  sig <- gsub(from[i], to[i], sig, fixed = TRUE)
}
writeLines(fix_links(sig), "R/signature.R")
cat(sprintf("copied %d objects; R/ now %d lines\n", length(move),
            sum(vapply(c("R/normalize.R", "R/stopwords-tokens.R", "R/signature.R"),
                       function(f) length(readLines(f)), 1L))))

# check in a scratch package, so this works before or without DESCRIPTION
tmp <- file.path(tempdir(), "npnormalize"); unlink(tmp, recursive = TRUE)
dir.create(file.path(tmp, "R"), recursive = TRUE)
invisible(file.copy(c("R/normalize.R", "R/stopwords-tokens.R", "R/signature.R"), file.path(tmp, "R")))
writeLines(c("Package: npnormalize", "Version: 0.0.0.9000", "Title: Check", "Description: Check.",
             "License: MIT", "Imports: data.table, datasets, stats, stringi, stringr, tools, utils"),
           file.path(tmp, "DESCRIPTION"))
writeLines(c('exportPattern("^np_")', "importFrom(stats, setNames)"), file.path(tmp, "NAMESPACE"))
suppressMessages(pkgload::load_all(tmp, quiet = TRUE, export_all = TRUE))
dn <- npmatch::np_normalize_signature(detail = TRUE)
dz <- npnormalize::np_normalize_signature(detail = TRUE)
cat("signature  npmatch", dn$signature, " npnormalize", dz$signature, "\n")
ok <- identical(dn$signature, dz$signature) && identical(dn$components, dz$components) &&
  !length(dz$missing)
if (!is.na(ref_pq)) {
  cols <- c(".id", ".ein", "name", "dba", "division", "street", "unit", "city", "county", "state",
            "zip5", "zip_plus4", "active", "variant_class", "address_class", "layer")
  ref <- arrow::read_parquet(ref_pq, col_select = dplyr::all_of(cols))
  set.seed(1); smp <- as.data.frame(ref[sample(nrow(ref), min(50000, nrow(ref))), ])
  x <- npmatch::np_normalize(smp); y <- npnormalize::np_normalize(smp)
  k <- x$name_key
  same <- c(normalize = identical(x, y),
            name_freq = identical(npmatch::np_name_freq(k), npnormalize::np_name_freq(k)),
            token_idf = identical(npmatch::np_token_idf(k), npnormalize::np_token_idf(k)),
            addr_freq = identical(
              unclass(npmatch::np_addr_freq(x$street_key, x$zip5, x$street_unit_id, k)),
              unclass(npnormalize::np_addr_freq(x$street_key, x$zip5, x$street_unit_id, k))))
  cat(sprintf("on %s reference rows, identical: %s\n", format(nrow(smp), big.mark = ","),
              paste(names(same), same, collapse = ", ")))
  ok <- ok && all(same)
}
cat(if (ok) "EXTRACTION OK\n" else "EXTRACTION DIFFERS\n")
quit(status = if (ok) 0 else 1)
