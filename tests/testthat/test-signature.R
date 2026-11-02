# np_normalize_signature() has one job: move when the normalizer's behaviour
# moves, and stay put otherwise. Both halves need testing -- a signature that
# never changes is useless, and one that changes on a comment is worse than
# useless because people route around it. Moved from npmatch, with the pinned
# value added.

test_that("the signature is the pinned value", {
  # Any artifact built against an earlier npnormalize was stamped with an
  # earlier value. If this fails, the normalizer's behaviour changed: that is
  # allowed, but it is a deliberate release (and a matchdb rebuild), never a
  # side effect. Update the pin in the same PR that explains the change.
  #
  # v1-3e7b9f9d59bbb19e  0.1.0, 0.1.1 -- the value npmatch gave before the move
  # v1-6d90b52d8b781673  0.1.2 -- BUILDING added to .np_unit_designators (#7),
  #                      which moves street_key and street_unit on any address
  #                      spelling the designator out, so cached keys must be
  #                      rebuilt.
  # v1-592912060053c4c3  0.1.3 -- a line naming several units keeps the most
  #                      specific (.np_unit_rank, .np_pick_unit), and the house
  #                      number is a whole token (.np_parse_street), which moves
  #                      street_unit, street_unit_id, street_num and street_name.
  # v1-1179714ce1e9d31f  0.1.4 -- street_has_box added (.np_box_pat,
  #                      .np_has_box) and .np_parse_street's box gate anchored
  #                      (#9), which adds a column and moves street_num and
  #                      street_name on a street that merely carries a box.
  # v1-533f186c123357cf  0.1.5 -- a box identifier is digits OR a single
  #                      trailing letter (#12), so the lettered boxes join
  #                      is_po_box and lose their address key; the identifier
  #                      is read by one helper (.np_box_identifier) that the
  #                      key rewrite and street_num share, which also recovers
  #                      the box number on the POB and "PO <n>" spellings.
  # v1-d49b18cc81ab79fb  0.1.6 -- the box vocabulary takes the spellings #13
  #                      measured (PO BX, PB, P B0X, POSTAL OFC BOX, APDO,
  #                      DRAWER); .np_mailonly_pat and .np_is_mailonly add
  #                      is_mail_only, a second gate on the address key for
  #                      general delivery and military mail; .np_mail_key adds
  #                      the mail_key column; and .np_box_identifier reads the
  #                      digits after the designator rather than anywhere in
  #                      the key, which is what keeps "P B0X 102" off "PO BOX 0".
  # v1-59c6e84c5f38e9f5  0.1.7 -- a hyphen in a leading house number is closed
  #                      up rather than spaced (.np_hyphen_house,
  #                      .np_join_house_number, #16), so the two filed
  #                      spellings of one Queens or Hawaii address share a
  #                      street_key and street_num stops truncating; and
  #                      .np_abbrev takes eleven further spellings of
  #                      FOUNDATION, three of them a word a line break split
  #                      (.np_split_words, .np_fold_split, #17), which moves
  #                      name_full, name_key, name_form, dba_key and
  #                      division_key.
  # v1-5e901add4a04a5d6  0.1.8 -- .np_hyphen_house stops joining a lone
  #                      compass letter, because "1002-E SENECA ST" is 1002
  #                      East Seneca and 0.1.7 made it "1002E SENECA ST",
  #                      keyed apart from the spelling with a space. 459
  #                      strings of the 22,026,817-row address table, 39 of
  #                      the join's 1,496 address splits.
  expect_identical(np_normalize_signature(), "v1-5e901add4a04a5d6")
})

test_that("the signature history dates the installed signature (#20)", {
  # The pin above is prose beside a literal; this is the machine-readable half,
  # and the reason it exists is that consumers stamp provenance headers from
  # packageVersion(), which dates the CURRENT signature and is no help for a
  # historical one. matchdb and pfmatch each dated v1-59c6e84c5f38e9f5 by hand
  # from NEWS, which is an inference in a header that should carry a record.
  #
  # This assertion is the drift guard: the table must name the signature the
  # installed package actually computes, with the installed version. Add a
  # release without adding its row and this fails.
  h <- np_signature_history(np_normalize_signature())
  expect_equal(nrow(h), 1L)
  expect_identical(h$package, "npnormalize")
  # `version` is the release that INTRODUCED the signature, so it is at or
  # behind the installed one -- a release that changes no rule reports its
  # predecessor's value, as 0.1.1 and 0.1.9 both do. compareVersion, not `<=`:
  # "0.1.10" sorts before "0.1.8" as a string, which would fail a correct
  # install on the first double-digit patch.
  expect_true(utils::compareVersion(
    as.character(utils::packageVersion("npnormalize")), h$version) >= 0)

  full <- np_signature_history()
  expect_false(any(duplicated(full$signature)))
  expect_true(all(grepl("^v1-[0-9a-f]{16}$", full$signature)))
  # every npnormalize row carries a version: this package computed those values
  expect_false(any(is.na(full$version[full$package == "npnormalize"])))

  # a pre-split value is LISTED, so a caller can tell "not an npnormalize
  # signature" from "a signature I do not have a row for". Two of the three
  # were dated from a consumer's run-time record naming the npmatch commit.
  pre <- np_signature_history("v1-421e1e2a6afb024e")
  expect_equal(nrow(pre), 1L)
  expect_identical(pre$package, "npmatch")
  expect_identical(pre$version, "0.0.0.9000")
  expect_match(pre$summary, "f14f1d9", fixed = TRUE)

  # and the one with no commit recorded anywhere stays undated rather than
  # being inferred from the releases either side of it
  expect_true(is.na(np_signature_history("v1-b42811fe6601afe6")$version))

  expect_equal(nrow(np_signature_history("v1-0000000000000000")), 0L)
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
