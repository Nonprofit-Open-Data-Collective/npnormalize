# The patterns np_pattern() publishes are consumed by a second regex engine.
# matchdb cannot call an R function from SQL -- DuckDB's R client registers data
# frames and Arrow tables, not scalar UDFs -- so md_place_key() is a macro over
# a regex string, and the only thing keeping that macro and np_addr_key() in
# agreement is that both read the same string and that the string means the
# same to both engines. These tests are that guarantee.

test_that("the shared patterns mean the same thing in R and in DuckDB's RE2", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")
  fixture <- c("PO BOX 12", "P O BOX 12", "POBOX 12", "POB 25161", "PO B 445",
               "PO 1609", "BOX 12", "PO BOX A", "PO BOX Z", "BOX R", "PO BOX",
               "PO BOX AB", "POST OFC", "22009 BOX ELDER RD", "BOXWOOD LN",
               "211 EMMET ST S PO BOX", "ONE HARRISON PLZ BOX 5079",
               "PO BOX 5371 MSC RC 507", "RR 1 BOX 8", "STE 300", "# 12", "",
               # 0.1.6: the widened head and the mail-only designators. The
               # nested non-capturing group in the drawer alternative is the
               # thing most likely to mean something different to RE2, and
               # "GEN DELANEY ST" is the \b that keeps "GEN DEL" off a street.
               "PO BX 24514", "PB 150", "PB BOX 6128", "P B0X 102", "PBOX 12",
               "POSTAL OFC BOX 54", "APDO 1391", "POSTAL DRAWER 1549",
               "DRAWER B", "PO DRAWER D", "P O DRAWER B", "DRAWERA",
               "DRAWER JJ EMORY UNIVERSITY", "POST OFC DRAWER NINE",
               "GENERAL DELIVERY", "GEN DEL", "GEN DELANEY ST", "APO",
               "APO AE 09096", "FPO AP 96310", "PSC 303 BOX 24",
               "CMR 467 BOX 7000", "1206 GRAIN BIN RD", "1821 FULTON ST MAILBOX 1")
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  arr <- paste0("['", paste(gsub("'", "''", fixture), collapse = "', '"), "']")
  for (nm in c("pobox", "mailonly", "box", "unit_id")) {
    pat <- np_pattern(nm)
    re2 <- DBI::dbGetQuery(con, sprintf(
      "SELECT regexp_matches(s, '%s') AS hit FROM (SELECT unnest(%s) AS s)",
      gsub("'", "''", pat), arr))$hit
    expect_identical(grepl(pat, fixture), re2)
  }
})

test_that("the shared patterns stay inside the subset both engines accept", {
  # RE2 has no lookaround, and R's own default engine has none either without
  # perl = TRUE -- a lookahead is rejected by BOTH, which is what makes this a
  # cheap guard rather than a DuckDB-specific one. The perl-only shorthands are
  # out for the same reason.
  for (nm in c("pobox", "mailonly", "box", "unit_id")) {
    pat <- np_pattern(nm)
    expect_false(grepl("\\(\\?[=!<]", pat))
    expect_false(grepl("\\\\[dwsDWS]", pat))
    expect_silent(grepl(pat, "PO BOX 1"))   # compiles without perl = TRUE
  }
})

test_that("a SQL copy of the address key needs both gates, and group 2 is the id", {
  # Two things a hand-ported macro gets wrong. First, np_addr_key() blanks on
  # the UNION of the two patterns, so a macro that reads only "pobox" is
  # narrower than the function -- which is exactly how matchdb's lettered-box
  # drift happened, and its fixture could not catch it.
  k <- c("PO BOX 12", "GENERAL DELIVERY", "PSC 303 BOX 24", "DRAWER B",
         "123 MAIN ST", "RR 1 BOX 8")
  only_pobox <- grepl(np_pattern("pobox"), k)
  both <- only_pobox | grepl(np_pattern("mailonly"), k)
  expect_false(identical(only_pobox, both))
  expect_equal(nzchar(np_addr_key(k, "59801")), !both)

  # Second, the identifier is capture group 2 of the pobox pattern and a
  # consumer reads it by index. The drawer alternative nests a group inside the
  # head, and it has to stay non-capturing or group 2 silently becomes the
  # drawer prefix.
  m <- regmatches(k, regexec(np_pattern("pobox"), k))
  expect_equal(m[[1]][3], "12")
  expect_equal(m[[4]][3], "B")
  pat <- np_pattern("pobox")
  n_capturing <- lengths(regmatches(
    pat, gregexpr("\\((?!\\?:)", pat, perl = TRUE)))
  expect_equal(n_capturing, 2L)   # the head and the identifier, nothing else
})

test_that("the mail-only pattern is composed from one vocabulary too", {
  expect_identical(
    npnormalize:::.np_mailonly_pat,
    paste0("^(", paste(npnormalize:::.np_mail_head, collapse = "|"), ")\\b"))
  expect_true(".np_mailonly_pat" %in%
                npnormalize:::.np_signature_registry()$tables)
  expect_true(".np_mail_head" %in% npnormalize:::.np_signature_exempt())
})

test_that("the box patterns are composed from one vocabulary", {
  # The head designators and the identifier live in one place each, so a
  # spelling is added once. Only the composed pattern is in the signature
  # registry: editing a piece still moves the signature, while rearranging the
  # pieces without changing the pattern does not.
  expect_identical(
    npnormalize:::.np_pobox_pat,
    paste0("^(", paste(npnormalize:::.np_box_head, collapse = "|"), ") ?#? ?(",
           npnormalize:::.np_box_id, ")"))
  expect_true(all(c(".np_pobox_pat", ".np_box_pat", ".np_unit_id_strip") %in%
                    npnormalize:::.np_signature_registry()$tables))
})
