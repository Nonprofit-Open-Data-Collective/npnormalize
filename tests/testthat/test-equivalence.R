# While npmatch still carries its own copy of the normalizer (until it imports
# this package), the two must agree exactly. Once npmatch re-exports these
# functions the comparison is trivially true, and this file can go.

test_that("npnormalize and npmatch agree: signature, keys and statistics", {
  skip_if_not_installed("npmatch")
  expect_identical(np_normalize_signature(), npmatch::np_normalize_signature())
  expect_identical(np_normalize_signature(detail = TRUE)$components,
                   npmatch::np_normalize_signature(detail = TRUE)$components)
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
  a <- np_normalize(d); b <- npmatch::np_normalize(d)
  expect_identical(a, b)
  k <- a$name_key
  expect_identical(np_name_freq(k), npmatch::np_name_freq(k))
  expect_identical(np_token_idf(k), npmatch::np_token_idf(k))
  expect_identical(unclass(np_addr_freq(a$street_key, a$zip5, a$street_unit_id, k)),
                   unclass(npmatch::np_addr_freq(a$street_key, a$zip5, a$street_unit_id, k)))
  expect_identical(np_name_core(d$name), npmatch::np_name_core(d$name))
  expect_identical(np_stopwords(), npmatch::np_stopwords())
  expect_identical(np_name_rules(), npmatch::np_name_rules())
})
