# Moved from npmatch's tests/testthat/test-normalize.R. The tests that need
# blocking or comparison (placeholders getting no candidates; two missing
# streets not agreeing) stay in npmatch.

test_that("name_key uppercases, de-punctuates, and strips trailing legal suffixes", {
  d <- np_normalize(np_test_frame(.id = c("1", "2", "3"),
                                  name = c("Widget, LLC", "Acme Corp.", "Globex Inc"),
                                  state = "AZ"))
  expect_equal(d$name_key, c("WIDGET", "ACME", "GLOBEX"))
  expect_equal(d$name_form, c("LLC", "CORP", "INC"))
})

test_that("a leading THE is stripped from the match key but kept in name_full", {
  d <- np_normalize(np_test_frame(.id = c("1", "2"),
                                  name = c("THE SAN DIEGO EDUCATION FOUNDATION", "THEATER GUILD"),
                                  state = "CA"))
  expect_equal(d$name_key, c("SAN DIEGO EDUCATION", "THEATER GUILD"))  # THE stripped, THEATER intact
  expect_match(d$name_full[1], "^THE ")
})

test_that("generation, number, and ordinal features are extracted", {
  d <- np_normalize(np_test_frame(.ein = c("1", "2", "3", "4"),
        name = c("KEN GRIFFEY JR", "IBEW LOCAL 32", "FIRST BAPTIST CHURCH", "KEN GRIFFEY SR"),
        state = "AK"))
  expect_equal(d$name_gen, c("JR", NA, NA, "SR"))       # JR/SR only; roman is not generational
  expect_equal(d$name_gen_rank, c("2", NA, NA, "1"))
  expect_equal(d$name_nums, c(NA, "32", NA, NA))
  expect_equal(d$name_ord, c(NA, NA, "1", NA))
})

test_that("ordinal words are not treated as generation markers", {
  d <- np_normalize(np_test_frame(.ein = "1", name = "SECOND BAPTIST CHURCH", state = "AK"))
  expect_true(is.na(d$name_gen))
  expect_equal(d$name_ord, "2")
})

test_that("address normalization splits zip5 and strips the unit from the key", {
  d <- np_normalize(np_test_frame(.id = "1", name = "X", street = "3406 GLACIER HWY STE A",
                                  zip5 = "99801-9501", state = "AK"))
  expect_equal(d$zip5, "99801")
  expect_equal(d$street_key, "3406 GLACIER HWY")
  expect_equal(d$street_unit, "STE A")
})

test_that("possessive apostrophes are deleted, not spaced, so the query matches the BMF", {
  # The IRS BMF holds "St. Luke's Hospital" as "ST LUKES HOSPITAL". Turning the
  # apostrophe into a space would give "ST LUKE S HOSPITAL" on the query side
  # only, and no possessive name could ever clear an exact-name pass.
  q <- np_test_frame(.id = as.character(1:4),
        name = c("BO'S PLACE", "St Luke's Hospital", "The Children's Museum of NH",
                 "L'Arche Mobile"), state = "TX")
  r <- np_test_frame(.ein = as.character(1:4),
        name = c("BOS PLACE", "ST LUKES HOSPITAL", "CHILDRENS MUSEUM OF NH", "LARCHE MOBILE"),
        state = "TX")
  expect_equal(np_normalize(q)$name_key, np_normalize(r)$name_key)
})

test_that("periods join an initialism but still break words that were already apart", {
  d <- np_normalize(np_test_frame(.id = c("1", "2", "3"),
        name = c("F.I.N.D.", "U.S.A. Today Fund", "Acme Inc. of America"), state = "CA"))
  expect_equal(d$name_full, c("FIND", "USA TODAY FUND", "ACME INC OF AMERICA"))
})

test_that("hyphens, ampersands, and slashes still separate tokens", {
  # These survive in the BMF on both sides, so they must keep the old behaviour.
  d <- np_normalize(np_test_frame(.id = c("1", "2", "3"),
        name = c("MID-ATLANTIC MINISTRIES", "Smith & Jones Fund", "Vedic Society C/O Ed"),
        state = "MD"))
  expect_equal(d$name_full,
               c("MID ATLANTIC MINISTRIES", "SMITH AND JONES FUND", "VEDIC SOCIETY C O ED"))
})

test_that("990-style abbreviations expand; PHYS is left alone", {
  expect_equal(np_name_core(c("NYP FDN", "ACME HLTH SYS", "UNIVERSITY REG MED CTR",
                              "Pine Hosp Fndtn", "Delta Mgmt Srvcs", "PHYS ED BOOSTERS")),
               c("NYP FOUNDATION", "ACME HEALTH SYSTEM", "UNIVERSITY REGIONAL MEDICAL CENTER",
                 "PINE HOSPITAL FOUNDATION", "DELTA MANAGEMENT SERVICES", "PHYS ED BOOSTERS"))
})

test_that("name_core keeps a charity and its foundation apart", {
  # name_key strips trailing FOUNDATION / TRUST / SOCIETY, so these collide there
  x <- c("PEOPLE OF FAITH INC", "PEOPLE OF FAITH FOUNDATION INC",
         "Pueblo Zoological Society", "Pueblo Zoological Society Foundation",
         "Greater Horizons Foundation", "Greater Horizons Trust")
  k <- np_name_core(x)
  expect_equal(k, c("PEOPLE FAITH", "PEOPLE FAITH FOUNDATION",
                    "PUEBLO ZOOLOGICAL SOCIETY", "PUEBLO ZOOLOGICAL SOCIETY FOUNDATION",
                    "GREATER HORIZONS FOUNDATION", "GREATER HORIZONS TRUST"))
  expect_equal(length(unique(k)), 6L)
  # connector words and legal forms drop anywhere; possessives join
  expect_equal(np_name_core(c("The Sons of the Republic of Texas", "SONS REPUBLIC TEXAS INC",
                              "Abilities at Eagle's Nest, Inc.", "THE CO")),
               c("SONS REPUBLIC TEXAS", "SONS REPUBLIC TEXAS", "ABILITIES AT EAGLES NEST", ""))
  expect_equal(np_name_core(c(NA, "")), c("", ""))
  expect_true(np_name_placeholder(NA))
  # the column np_normalize() adds is the same rule
  d <- np_normalize(np_test_frame(.ein = "1", name = x[2], state = "CO"))
  expect_equal(d$name_core, k[2])
})

test_that("placeholder names are flagged", {
  x <- c("SEE SCHEDULE O", "See Attached", "N/A", "SAME AS ABOVE", "NONE", "100", "",
         "Acme Fdn", "See Change Coalition", "NA Health Center")
  expect_equal(np_name_placeholder(x), c(rep(TRUE, 7), FALSE, FALSE, FALSE))
  d <- np_normalize(np_test_frame(.id = c("1", "2"), name = c("SEE SCHEDULE O", "ACME FDN"),
                                  state = "AZ"))
  expect_equal(d$name_placeholder, c(TRUE, FALSE))
})

test_that("letters with no accent to drop fold to ASCII instead of splitting the word", {
  # matchdb's md_light_key() maps the same letters, and the two keys have to
  # agree character for character or a cached reference key never meets the
  # query key normalized at run time. An unmapped letter becomes a space, which
  # used to split the word it sat in: "STRA E FUND", "RESUND TRUST".
  x <- c("Straße Fund", "Øresund Trust", "Łucja Society",
         "Đuro Institute", "Æon Fund", "Œuvre Fund",
         "Þor Foundation", "Muñoz Center", "École Fund")
  expect_equal(np_name_core(x),
               c("STRASSE FUND", "ORESUND TRUST", "LUCJA SOCIETY",
                 "DURO INSTITUTE", "AEON FUND", "OEUVRE FUND",
                 "THOR FOUNDATION", "MUNOZ CENTER", "ECOLE FUND"))
  # the fold is case-blind: the key cannot depend on how the name was written
  expect_equal(np_name_core(c("straße fund", "øresund trust")),
               c("STRASSE FUND", "ORESUND TRUST"))
  # a spelled-out name reaches the same key, which is the point of folding
  expect_equal(np_name_core("Strasse Fund"), np_name_core("Straße Fund"))
})

test_that("tabs and newlines separate tokens rather than joining words", {
  expect_equal(np_name_core("Acme\tHealth\nFund"), "ACME HEALTH FUND")
})

test_that("np_name_rules() exposes the tables the normalizer uses", {
  r <- np_name_rules()
  expect_named(r, c("abbrev", "core_stop", "legal_suffixes", "special_letters",
                    "placeholder_re", "placeholder_tok"))
  expect_equal(r$special_letters[["ß"]], "SS")
  expect_equal(r$special_letters[["Þ"]], "TH")
  expect_equal(r$abbrev[["FDN"]], "FOUNDATION")
  expect_false("PHYS" %in% names(r$abbrev))
  expect_true(all(c("OF", "INC") %in% r$core_stop))
  expect_false(any(c("FOUNDATION", "TRUST") %in% r$core_stop))
})

test_that("a missing street or name is empty, never the text NA", {
  # paste() inside the token replacement used to turn NA into "NA", so every
  # record with no street had street_key "NA" and agreed with every other one
  r <- np_normalize(np_test_frame(
    .ein = c("EIN-10-0000001", "EIN-10-0000002", "EIN-10-0000003"),
    name = c("A CLUB", "B CLUB", NA), street = c(NA, "", "1 MAIN ST"),
    city = "X", state = "GA", zip5 = "30341"))
  expect_identical(r$street_key[1:2], c("", ""))           # NA and "" alike
  expect_true(is.na(r$street_name[1]) && is.na(r$street_name[2]))
  expect_identical(r$street_key[3], "1 MAIN ST")
  expect_false(any(c(r$street_key, r$street_name, r$name_key, r$name_full) %in% "NA"))
  expect_identical(r$name_key[3], "")
  q <- np_normalize(np_test_frame(.id = c("1", "2"), name = c("A", "B"), street = NA))
  expect_identical(q$street_key, c("", ""))
})

test_that("a street literally named NA is still a street", {
  r <- np_normalize(np_test_frame(.ein = "EIN-10-0000001", name = "A CLUB", street = "12 NA ST"))
  expect_identical(r$street_key, "12 NA ST")
})
