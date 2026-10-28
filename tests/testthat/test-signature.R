# np_normalize_signature() has one job: move when the normalizer's behaviour
# moves, and stay put otherwise. Both halves need testing -- a signature that
# never changes is useless, and one that changes on a comment is worse than
# useless because people route around it. Moved from npmatch, with the pinned
# value added.

test_that("the signature is the one npmatch gave before the move", {
  # Every artifact matchdb has published was stamped with this value. If this
  # fails, the normalizer's behaviour changed: that is allowed, but it is a
  # deliberate release (and a matchdb rebuild), never a side effect. Update the
  # pin in the same PR that explains the change.
  expect_identical(np_normalize_signature(), "v1-3e7b9f9d59bbb19e")
})

test_that("the signature is stable within a session and across calls", {
  expect_identical(np_normalize_signature(), np_normalize_signature())
  expect_match(np_normalize_signature(), "^v1-[0-9a-f]{16}$")
})

test_that("detail = TRUE localizes the signature to its components", {
  d <- np_normalize_signature(detail = TRUE)
  expect_s3_class(d, "np_signature")
  expect_identical(d$signature, np_normalize_signature())
  expect_true(length(d$components) > 30L)
  expect_true(all(grepl("^[0-9a-f]{32}$", d$components)))
  expect_identical(d$npnormalize_version, as.character(utils::packageVersion("npnormalize")))
  # every registered name is reported, so a mismatch is attributable
  reg <- sort(unique(unlist(.np_signature_registry(), use.names = FALSE)))
  expect_identical(names(d$components), reg)
  expect_output(print(d), "npnormalize")
})

test_that("a comment-only edit does not move the signature", {
  # reformatting and documentation must not invalidate a cache. Simulated by
  # hashing a function against a commented copy of itself.
  f <- .np_strip_lead_the
  g <- eval(parse(text = paste0(
    "function(x) {\n",
    "  # a newly added comment that changes nothing\n",
    "  out <- sub('^THE ', '', x)\n",
    "  ifelse(nzchar(out), out, x)  # trailing comment\n",
    "}")), envir = asNamespace("npnormalize"))
  txt <- function(fn) paste(deparse(utils::removeSource(fn), width.cutoff = 500L,
                                    control = c("keepInteger", "keepNA")),
                            collapse = "\n")
  expect_identical(txt(f), txt(g))
})

test_that("a rule-table change moves the signature", {
  base <- np_normalize_signature()
  ns <- asNamespace("npnormalize")
  old <- get(".np_abbrev", envir = ns)
  unlockBinding(".np_abbrev", ns)
  on.exit({ assign(".np_abbrev", old, envir = ns); lockBinding(".np_abbrev", ns) }, add = TRUE)
  assign(".np_abbrev", c(old, ZZZTEST = "ZZZ"), envir = ns)
  expect_false(identical(np_normalize_signature(), base))
  # and it is attributable to the table that actually moved
  d <- np_normalize_signature(detail = TRUE)
  assign(".np_abbrev", old, envir = ns)
  d0 <- np_normalize_signature(detail = TRUE)
  moved <- names(d$components)[d$components != d0$components]
  expect_identical(moved, ".np_abbrev")
})

test_that("a function-body change moves the signature", {
  base <- np_normalize_signature()
  ns <- asNamespace("npnormalize")
  old <- get(".np_strip_lead_the", envir = ns)
  unlockBinding(".np_strip_lead_the", ns)
  on.exit({ assign(".np_strip_lead_the", old, envir = ns)
            lockBinding(".np_strip_lead_the", ns) }, add = TRUE)
  assign(".np_strip_lead_the", function(x) {
    out <- sub("^(THE|A) ", "", x)
    ifelse(nzchar(out), out, x)
  }, envir = ns)
  expect_false(identical(np_normalize_signature(), base))
})

test_that("the registry and the exemption list cover everything the normalizer files define", {
  # A new rule table or helper must be classified as covered or exempt, or this
  # fails. Without it the signature could miss real drift.
  covered <- unlist(.np_signature_registry(), use.names = FALSE)
  exempt  <- .np_signature_exempt()
  root <- testthat::test_path("..", "..")
  src <- file.path(root, "R", c("normalize.R", "stopwords-tokens.R"))
  skip_if_not(all(file.exists(src)), "source tree not available (installed package)")
  top <- grep("^(\\.np_|np_)[A-Za-z0-9_.]* *<-", unlist(lapply(src, readLines)), value = TRUE)
  defined <- unique(sub(" *<-.*$", "", top))
  unclassified <- setdiff(defined, c(covered, exempt))
  expect_identical(unclassified, character(0),
    info = paste("unclassified objects:", paste(unclassified, collapse = ", ")))
})

test_that("every registered name resolves", {
  reg <- unlist(.np_signature_registry(), use.names = FALSE)
  ns <- asNamespace("npnormalize")
  missing <- reg[!vapply(reg, exists, logical(1), envir = ns, inherits = FALSE)]
  expect_identical(missing, character(0),
    info = paste("registered but absent:", paste(missing, collapse = ", ")))
})
