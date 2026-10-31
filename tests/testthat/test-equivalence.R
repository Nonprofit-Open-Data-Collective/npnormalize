# While npmatch still carries its own copy of the normalizer (until it imports
# this package), the two must agree -- apart from what this package has
# deliberately changed since the move. Once npmatch re-exports these functions
# the comparison is trivially true, and this file can go.

test_that("npnormalize and npmatch agree: keys, statistics, and only #7 moved", {
  skip_if_not_installed("npmatch")
  skip_if(!exists(".np_unit_pat", asNamespace("npmatch"), inherits = FALSE),
          "npmatch re-exports this package; the comparison is trivially true")
  # npmatch's copy is frozen at the move, so it predates the 0.1.2 BUILDING fix
  # (#7) and the signatures no longer match. The useful assertion is no longer
  # that they are equal but that NOTHING ELSE drifted: the fix touches exactly
  # the designator table and the pattern built from it, and every other
  # component hash is still identical.
  a <- np_normalize_signature(detail = TRUE)$components
  b <- npmatch::np_normalize_signature(detail = TRUE)$components
  expect_identical(names(a), names(b))
  expect_identical(names(a)[a != b], c(".np_unit_designators", ".np_unit_pat"))
  d <- np_test_frame(
    .ein = sprintf("EIN-%02d", 1:8),
    name = c("The Children's Museum of NH", "ST LUKE'S HOSPITAL FDN", "F.I.N.D., Inc.",
             "Straße Fund", "SEE SCHEDULE O", NA, "IBEW LOCAL 32", "Second Baptist Church"),
    dba = c("", "St Lukes", NA, "", "", "", "", ""),
    street = c("123 Main St Ste 300", "PO BOX 1558", "1180 NORTHERN BLVD - 2ND FL", NA, "",
               "12 NA ST", "430 W 7TH AVE # 202", "3575 ARDEN WAY PMB 306"),
    unit = c(NA, NA, NA, "STE 9", NA, NA, NA, NA),
    city = "X", state = c("NH", "Texas", "NY", "CA", "", "GA", "AK", "CA"),
    zip5 = c("03301", "75201-1234", "11101", "9", "", "30341", "99501", "95825"),
    zip_plus4 = c(NA, NA, "1234", NA, NA, NA, NA, NA))
  # No row here spells a unit designator out, so the fix does not reach the
  # output and the keys are still identical on every column.
  a <- np_normalize(d); b <- npmatch::np_normalize(d)
  expect_identical(a, b)
  # where it does reach, this package is the one that is right
  bldg <- np_test_frame(.id = "1", name = "ACME", state = "MA",
                        street = "100 CAMPUS CENTER BUILDING 86E")
  expect_equal(np_normalize(bldg)$street_unit, "BLDG 86E")
  expect_equal(npmatch::np_normalize(bldg)$street_unit, NA_character_)
  k <- a$name_key
  expect_identical(np_name_freq(k), npmatch::np_name_freq(k))
  expect_identical(np_token_idf(k), npmatch::np_token_idf(k))
  expect_identical(unclass(np_addr_freq(a$street_key, a$zip5, a$street_unit_id, k)),
                   unclass(npmatch::np_addr_freq(a$street_key, a$zip5, a$street_unit_id, k)))
  expect_identical(np_name_core(d$name), npmatch::np_name_core(d$name))
  expect_identical(np_stopwords(), npmatch::np_stopwords())
  expect_identical(np_name_rules(), npmatch::np_name_rules())
})
