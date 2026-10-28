# A frame in the shape np_normalize() reads: the fields npmatch's np_query() /
# np_reference() produce, unmapped ones NA, text squished. The same light
# hygiene npmatch applies, so these tests read as they did there.
np_test_fields <- c(".id", ".ein", "name", "dba", "division", "street", "unit", "city",
                    "county", "state", "zip5", "zip_plus4", "active")

np_test_frame <- function(...) {
  d <- data.frame(..., stringsAsFactors = FALSE)
  for (f in setdiff(np_test_fields, names(d))) d[[f]] <- NA_character_
  d <- d[, c(np_test_fields, setdiff(names(d), np_test_fields)), drop = FALSE]
  chr <- vapply(d, is.character, logical(1))
  d[chr] <- lapply(d[chr], function(v) stringr::str_squish(as.character(v)))
  d
}
