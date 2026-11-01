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
               "PO BOX 5371 MSC RC 507", "RR 1 BOX 8", "STE 300", "# 12", "")
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  arr <- paste0("['", paste(gsub("'", "''", fixture), collapse = "', '"), "']")
  for (nm in c("pobox", "box", "unit_id")) {
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
  for (nm in c("pobox", "box", "unit_id")) {
    pat <- np_pattern(nm)
    expect_false(grepl("\\(\\?[=!<]", pat))
    expect_false(grepl("\\\\[dwsDWS]", pat))
    expect_silent(grepl(pat, "PO BOX 1"))   # compiles without perl = TRUE
  }
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
