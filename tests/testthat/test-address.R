# Moved from npmatch's test-address-unit.R and test-address-class.R: the suite
# parser and np_addr_freq(). The tests that score or route a pair stay in
# npmatch.

test_that("unit designators are parsed, and ordinary words are not mistaken for them", {
  x <- c("123 Main St Ste 300", "123 Main St Suite. 300", "123 Main St # 300",
         "500 BROADWAY ROOM216", "123 Main St 2nd Floor", "1180 NORTHERN BLVD - 2ND FL",
         "30802 COAST HWY SPC F20", "3575 ARDEN WAY PMB 306", "2800 ADMIRAL ST TRLR 14",
         "10317 INDIGO BROOM LOOP", "22148 SHERMAN WAY", "1963 STERLING ST",
         "1617 W FLAGLER ST", "2815 E COMMUNITY DR", "8997 LOCKHART TRLR CT RD",
         "123 NO 5TH ST", "PO BOX 1558", "123 Main St")
  expect_equal(.np_extract_unit(x),
    c("STE 300", "STE 300", "# 300", "RM 216", "FL 2", "FL 2", "SPC F20",
      "PMB 306", "TRLR 14", rep(NA_character_, 9)))
  # the key loses the unit, the number-sign form included: the old strip ran
  # after cleaning, by which time the sign was a space, and left "300" behind
  expect_equal(.np_street_key(x[1:9]),
    c("123 MAIN ST", "123 MAIN ST", "123 MAIN ST", "500 BROADWAY", "123 MAIN ST",
      "1180 NORTHERN BLVD", "30802 COAST HWY", "3575 ARDEN WAY", "2800 ADMIRAL ST"))
  # a street whose name merely contains a designator keeps every token: the old
  # pattern read "BROOM LOOP" as room "OOM LOOP" and keyed this "10317 INDIGO B"
  expect_equal(.np_street_key("10317 INDIGO BROOM LOOP"), "10317 INDIGO BROOM LOOP")
  # a designator inside a word must not MASK the real unit either
  expect_equal(.np_extract_unit("259 N RADNOR CHESTER RD STE 150"), "STE 150")
})

test_that("a long designator .np_street_types contracts is extracted as a unit", {
  # The unit is extracted from the RAW street; the BUILDING -> BLDG contraction
  # happens two lines later, in .np_street_key(). So a long form missing from
  # .np_unit_designators split two spellings of one address: one kept the unit
  # inside street_key and recorded no street_unit, the other stripped it
  # correctly, and the pair could neither block nor compare on the unit.
  # Reported from pfmatch on the 990-PF recipient-address line (#7).
  s <- c("100 CAMPUS CENTER BUILDING 86E", "100 CAMPUS CENTER BLDG 86E")
  expect_equal(.np_extract_unit(s), c("BLDG 86E", "BLDG 86E"))
  expect_equal(.np_street_key(s), rep("100 CAMPUS CENTER", 2))

  # The general case, because this class of bug is invisible one case at a time:
  # the street key looks right either way. Every .np_street_types key whose
  # abbreviation is a designator must be a designator itself.
  long  <- names(.np_street_types)
  short <- unname(.np_street_types)
  d     <- names(.np_unit_designators)
  expect_equal(long[short %in% d & !(long %in% d)], character(0))

  # and BUILDING is still a street word: it reads as a designator only when an
  # identifier follows it, so a street named for a building keeps every token
  expect_equal(.np_extract_unit(c("1 EMPIRE STATE BUILDING", "4 BUILDING COMMISSION RD",
                                  "10 BUILDINGS WAY")),
               rep(NA_character_, 3))
  expect_equal(.np_street_key("4 BUILDING COMMISSION RD"), "4 BLDG COMMISSION RD")
})

test_that("a line naming several units keeps the most specific, not the first", {
  # Every unit is cut from street_key, but street_unit holds one. Keeping the
  # first one written threw away the one that tells occupants apart: every suite
  # of building 1 shared BLDG 1, and every mailbox of one mail store shared its
  # suite. Reported from matchdb's 0.1.2 rebuild (matchdb#29).
  x <- c("1 BETHANY RD BUILDING 1 STE 5", "BUILDING 114 16TH ST RM 3125",
         "2125 BISCAYNE BLVD STE 204 # 22915", "1633 MAIN ST STE A PMB 175",
         "1202 PLYMOUTH RD UNIT 1202 BLDG 12", "123 MAIN ST RM 3 FL 2",
         "1212 BATH AVE FL 6 STE 8", "5 SOUTHSIDE DR STE 11 STE 124")
  expect_equal(.np_extract_unit(x),
    c("STE 5", "RM 3125", "# 22915", "PMB 175", "UNIT 1202", "RM 3", "STE 8", "STE 124"))
  # the key still loses all of them
  expect_equal(.np_street_key(x[1:3]), c("1 BETHANY RD", "16TH ST", "2125 BISCAYNE BLVD"))
  # and the second address line is read by the same rule
  expect_equal(.np_extract_unit("1201 S CLEARVIEW PKWY", "BLDG B STE 500"), "STE 500")
  # every designator .np_norm_unit() can write has a rank, or the pick is NA
  expect_true(all(c(unname(.np_unit_designators), "#", "FL") %in% names(.np_unit_rank)))
})

test_that("the house number is a whole leading token", {
  # An ordinal street has none: the old rule read "16TH ST" as number "16T" on
  # street "H". A grid number is one token; a number run into the street name is
  # its digits, unless they could begin an ordinal.
  k <- c("16TH ST", "6TH AND CHESTNUT ST", "123A MAIN ST", "123 MAIN ST",
         "16W540 BLUFF RD", "0S064 KERRY CT", "921AIRPORT SERVICE RD", "2436TH ST",
         "PO BOX 12", "")
  p <- .np_parse_street(k)
  expect_equal(p$street_num, c(NA, NA, "123A", "123", "16W540", "0S064", "921", NA, "12", NA))
  expect_equal(p$street_name, c("16TH", "6TH AND CHESTNUT", "MAIN", "MAIN", "BLUFF", "KERRY",
                                "AIRPORT SERVICE", "2436TH", "PO BOX", NA))
  expect_equal(p$street_type, c("ST", "ST", "ST", "ST", "RD", "CT", "RD", "ST", NA, NA))
})

test_that("the compared identifier ignores how the designator was spelled", {
  # "STE 300", "Suite 300" and "# 300" are one office; 320 and 380 are not the
  # same office to any degree, which is why this is an id and not a string score
  ids <- .np_unit_id(.np_extract_unit(
    c("1 A St Ste 300", "1 A St Suite 300", "1 A St #300", "1 A St Ste D-2",
      "1 A St FL 11TH", "1 A St 11th Floor")))
  expect_equal(ids, c("300", "300", "300", "D2", "11", "11"))
})

test_that("a unit in the second address line is read, not ignored", {
  # SAM keeps the suite in physical_address_line_2.
  d <- np_test_frame(.id = as.character(1:3), name = "ACME FUND", street = "123 Main St",
                     unit = c("STE 300", "300", ""), state = "TX")
  q <- np_normalize(d)
  expect_equal(q$street_unit, c("STE 300", "# 300", NA))
  expect_equal(q$street_unit_id, c("300", "300", NA))
  # the street line wins when both name a unit
  q2 <- np_normalize(transform(d, street = "123 Main St Ste 410"))
  expect_equal(q2$street_unit_id, rep("410", 3))
})

test_that("street_has_box asks whether the street CARRIES a box, not whether it is one", {
  # #9: filers write the street on line 1 ending in the box WORD and carry the
  # box NUMBER alone on line 2, so a consumer holding a bare line-2 number has
  # nothing to tell a box number from a door. is_po_box cannot answer it -- it
  # is the gate that blanks the address key, and these are genuine streets that
  # should still block and still be counted.
  d <- np_test_frame(
    .ein = sprintf("%02d", 1:8), name = "ACME", state = "VA",
    street = c("211 EMMET STREET SOUTH PO BOX", "300 KENAN CENTER DRIVE - CAMPUS BOX",
               "4347 W NORTHWEST HWY STE 130 BOX", "ONE HARRISON PLAZA BOX 5079",
               "PO BOX A", "PO BOX 1367", "22009 BOX ELDER RD", "500 MAIN ST"))
  o <- np_normalize(d)
  expect_equal(o$street_has_box, c(rep(TRUE, 6), FALSE, FALSE))
  # and the first four are NOT boxes: the street key is kept, so they still
  # block. "PO BOX A" is one, as of 0.1.5 -- a lettered box is a box (#12).
  expect_equal(o$is_po_box, c(rep(FALSE, 4), TRUE, TRUE, FALSE, FALSE))
  expect_equal(o$street_key[1], "211 EMMET ST S PO BOX")
  expect_true(nzchar(np_addr_key(o$street_key[1], o$zip5[1])))
})

test_that("is_po_box implies street_has_box, and a BOX-named street implies neither", {
  # The implication is why the flag is read from the REWRITTEN key: a caller
  # with a cached street_key can recompute it, and no row can be a box without
  # carrying one. Asserted over every PO-box spelling .np_pobox_pat knows.
  # ("PO BOX #12" is not here: .np_unit_pat reads "#12" as a suite before the
  # street key is built, so that spelling keys as "PO BOX" with is_po_box
  # FALSE. street_has_box is TRUE either way, and the spelling does not occur
  # in the BMF at all -- 0 of 3,687,435 rows -- so there is nothing to measure
  # a fix against here.)
  boxes <- c("PO BOX 12", "P O BOX 12", "POBOX 12", "POB 12", "PO B 12",
             "PO 12", "P O 12", "BOX 12")
  d <- np_test_frame(.ein = sprintf("%02d", seq_along(boxes)), name = "ACME",
                     state = "TX", street = boxes)
  o <- np_normalize(d)
  expect_true(all(o$is_po_box))
  expect_true(all(o$street_has_box))

  # The end anchor is the whole guard. Dropping it would flag 127 BMF rows that
  # are streets NAMED for a box (dev/scan-box-component.R); the word boundary
  # alone handles BOXWOOD and BOXER, the anchor is what handles BOX ELDER.
  named <- c("22009 BOX ELDER RD", "21150 BOX SPRINGS RD", "2027 BOX RD",
             "55 BOXWOOD LANE", "1 BOXER ST", "3509 BOXDALE ST", "37 BOXFORD RD")
  d2 <- np_test_frame(.ein = sprintf("%02d", seq_along(named)), name = "ACME",
                      state = "UT", street = named)
  o2 <- np_normalize(d2)
  expect_false(any(o2$street_has_box))
  expect_false(any(o2$is_po_box))

  # DRAWER and BIN were measured and left out (55 and 28 rows), so they are not
  # box words here; a missing street is not a box either.
  d3 <- np_test_frame(.ein = c("1", "2", "3", "4"), name = "ACME", state = "GA",
                      street = c("PO DRAWER 220", "1535 W JEFFERSON ST BIN 42", NA, ""))
  expect_false(any(np_normalize(d3)$street_has_box))
})

test_that("a lettered box is a box, and the widening keeps what the digits form caught", {
  # #12. "PO BOX A" through "PO BOX Z" is 1,010 BMF rows in 41 keys, and every
  # one is a post office box -- there is no building at PO BOX Q. The digits-
  # only pattern left them out of is_po_box, so np_addr_key() counted their
  # holders as a building's tenants: 105 of their 825 address keys hold two or
  # more EINs, up to 15 at "PO BOX B 75785" (dev/audit-pobox.R).
  lettered <- c("PO BOX A", "PO BOX Q", "PO BOX Z", "P O BOX B")
  d <- np_test_frame(.ein = sprintf("%02d", seq_along(lettered)), name = "ACME",
                     state = "WV", street = lettered)
  o <- np_normalize(d)
  expect_true(all(o$is_po_box))
  expect_true(all(o$street_has_box))
  # the point of the change: the address key is blanked, so a lettered box
  # stops being counted as a shared building
  expect_equal(np_addr_key(o$street_key, o$zip5), rep("", length(lettered)))

  # The anchor sits on the LETTER branch only. A box NUMBER is routinely
  # followed by more text -- 1,141 BMF rows carry a mail stop, 136 carry a
  # street as well -- so anchoring the whole identifier would have dropped
  # them. The widened pattern must still flag every shape the digits form did.
  kept <- c("PO BOX 5371 MSC RC 507", "PO BOX 102175 KOOSER RD", "BOX 870136",
            "PO 1609", "POB 25161", "PO B 445", "POBOX 76", "PO BOX 1367")
  expect_true(all(np_is_po_box(kept)))

  # Two letters is the next word of a street name or label, not an identifier.
  not <- c("PO BOX AB", "POST OFC", "22009 BOX ELDER RD", "BOXWOOD LN")
  expect_false(any(np_is_po_box(not)))
})

test_that("np_is_po_box(), np_has_box() and np_pattern() are how a consumer asks", {
  # pfmatch kept its own unanchored BOX regex for exactly the np_has_box()
  # question, and an unanchored BOX claims 127 BMF rows whose street is merely
  # NAMED for a box. These accessors exist so no consumer has to keep one: they
  # take the raw line, key it, and answer.
  expect_identical(np_is_po_box(c("P.O. Box 1367", "114 High St")), c(TRUE, FALSE))
  expect_identical(np_has_box(c("211 Emmet Street South PO Box", "114 High St")),
                   c(TRUE, FALSE))
  # np_has_box() must not depend on np_normalize()'s "PO BOX <n>" rewrite:
  # "POBOX 12" carries no word boundary before BOX, so the tail pattern alone
  # cannot see it and only the head pattern can.
  expect_true(np_has_box("POBOX 12"))
  expect_true(all(np_has_box(c("PO BOX 12", "PO BOX A", "PO 12"))))
  expect_identical(np_is_po_box(NA_character_), FALSE)

  # The literals, for a consumer that cannot call an R function at all --
  # matchdb's DuckDB macros. Read from here rather than retyped.
  expect_identical(np_pattern("pobox"), npnormalize:::.np_pobox_pat)
  expect_identical(np_pattern("box"), npnormalize:::.np_box_pat)
  expect_identical(np_pattern("unit_id"), npnormalize:::.np_unit_id_strip)
  expect_identical(np_pattern(), npnormalize:::.np_pobox_pat)
  expect_error(np_pattern("nope"))
})

test_that("the street parse treats only an ANCHORED box as a box", {
  # The gate was an unanchored grepl("\\bBOX\\b"), which overwrote the parse of
  # 14,014 BMF rows (0.380%) whose street merely carries or is named for a box.
  k <- c("ONE HARRISON PLZ BOX 5079", "22009 BOX ELDER RD", "2027 BOX RD",
         "211 EMMET ST S PO BOX", "PO BOX 12", "PO BOX")
  p <- .np_parse_street(k)
  # a BOX-named street keeps its house number and its type, where it used to
  # lose both to street_num 5079 / street_name "PO BOX"
  expect_equal(p$street_num, c(NA, "22009", "2027", "211", "12", NA))
  expect_equal(p$street_name, c("ONE HARRISON PLZ BOX 5079", "BOX ELDER", "BOX",
                                "EMMET ST S PO BOX", "PO BOX", "PO BOX"))
  expect_equal(p$street_type, c(NA, "RD", "RD", NA, NA, NA))
  # the parse and the flag can no longer disagree about what a box is
  expect_equal(p$street_name == "PO BOX" & !is.na(p$street_num), .np_is_pobox(k))
})

test_that("np_addr_freq counts tenants per address and per suite, PO boxes aside", {
  af <- np_addr_freq(
    street_keys = c("430 W 7TH AVE", "430 W 7TH AVE", "430 W 7TH AVE",
                    "104 DIVISION ST", "PO BOX 80547"),
    zip5 = c("99501", "99501", "99501", "99762", "99708"),
    unit_ids = c("200", "202", "202", NA, NA))
  expect_s3_class(af, "np_addr_freq")
  expect_equal(af$addr[["430 W 7TH AVE 99501"]], 3L)
  expect_equal(af$units[["430 W 7TH AVE 99501"]], 2L)
  expect_equal(af$addr_unit[["430 W 7TH AVE 99501|202"]], 2L)
  expect_false("PO BOX 80547 99708" %in% names(af$addr))
  expect_equal(af$share_min, 10L)
})

# What a shared address IS, which decides what its evidence is worth. Counts
# alone cannot tell a federated parent from a fiscal sponsor; the share of
# records carrying the most common name can.

# n records at one address, with the names and suites given
at_one_address <- function(names, units = NA_character_, street = "127 FILMORE LN",
                           zip = "78701") {
  n <- length(names)
  np_test_frame(.ein = sprintf("%03d", seq_len(n)), name = names,
                street = ifelse(is.na(units), street, paste(street, units)),
                city = "AUSTIN", state = "TX", zip5 = zip, dba = "")
}

freq_of <- function(df, ...) {
  r <- np_normalize(df)
  np_addr_freq(r$street_key, r$zip5, r$street_unit_id, r$name_key, ...)
}

test_that("a federated address is told apart from a sponsor address", {
  # 12 chapters filing from one national office under one name
  fed <- freq_of(at_one_address(rep("PEO SISTERHOOD INTERNATIONAL CHAPTER", 12)))
  k <- "127 FILMORE LN 78701"
  expect_equal(fed$class[[k]], "federated")
  expect_equal(fed$n_names[[k]], 1L)
  expect_equal(fed$top_name_share[[k]], 1)
  # 12 unrelated foundations at a fiscal sponsor: the NAME separates them
  spo <- freq_of(at_one_address(paste(LETTERS[1:12], "FAMILY FOUNDATION")))
  expect_equal(spo$class[[k]], "shared")
  expect_equal(spo$n_names[[k]], 12L)
  expect_lt(spo$top_name_share[[k]], 0.5)
})

test_that("a multi-tenant building is recognised, and thin suite data is not", {
  k <- "127 FILMORE LN 78701"
  # every tenant records a distinct suite: the suite is the discriminator
  bld <- freq_of(at_one_address(paste(LETTERS[1:12], "ARTS COLLECTIVE"),
                                units = paste("STE", 100 + seq_len(12))))
  expect_equal(bld$class[[k]], "building")
  expect_equal(bld$units[[k]], 12L)
  expect_equal(bld$unit_coverage[[k]], 1)
  # the same building, but a suite recorded for only 2 of 12
  thin <- freq_of(at_one_address(paste(LETTERS[1:12], "ARTS COLLECTIVE"),
                                 units = c("STE 101", "STE 102", rep(NA, 10))))
  expect_equal(thin$units[[k]], 2L)
  expect_lt(thin$unit_coverage[[k]], 0.5)
  expect_equal(thin$class[[k]], "shared")      # not "building"
})

test_that("a handful of co-located records is a family cluster, not a crowd", {
  fam <- freq_of(at_one_address(c("PUEBLO ZOOLOGICAL SOCIETY",
                                  "PUEBLO ZOOLOGICAL SOCIETY FOUNDATION",
                                  "PUEBLO ZOOLOGICAL AUXILIARY")))
  expect_equal(fam$class[["127 FILMORE LN 78701"]], "cluster")
})

test_that("without names an address cannot be classified, and nothing breaks", {
  r <- np_normalize(at_one_address(rep("PEO SISTERHOOD INTERNATIONAL CHAPTER", 12)))
  af <- np_addr_freq(r$street_key, r$zip5, r$street_unit_id)   # no name_keys
  k <- "127 FILMORE LN 78701"
  expect_true(is.na(af$top_name_share[[k]]))
  expect_equal(af$class[[k]], "shared")        # crowded, but which kind is unknown
})

test_that("np_addr_key() is the key np_addr_freq() counts on, blank for a PO box", {
  expect_equal(np_addr_key(c("430 W 7TH AVE", "PO BOX 80547", ""), c("99501", "99708", "1")),
               c("430 W 7TH AVE 99501", "", ""))
})

test_that("np_unit_id() is the identifier np_normalize() puts in street_unit_id", {
  # the wrapper matchdb's md_unit_id() calls: one office however the suite is
  # written, and NA where there is none
  expect_equal(np_unit_id(c("STE 300", "# 300", "STE D-2", "FL 2", NA, "")),
               c("300", "300", "D2", "2", NA, NA))
  d <- np_normalize(np_test_frame(.id = as.character(1:5), name = "ACME FUND",
    street = c("1 A St Ste 300", "1 A St Suite 300", "1 A St #300", "1 A St Ste D-2", "1 A St"),
    state = "TX"))
  expect_identical(np_unit_id(d$street_unit), d$street_unit_id)
  expect_identical(np_unit_id(d$street_unit), .np_unit_id(d$street_unit))
})

test_that("np_unit_id() is NA on a line that names no unit", {
  # It is exported, so it gets handed raw free-text address lines -- pfmatch
  # reads the 990-PF recipient line with it. Ungated it reduced whatever it was
  # given and returned it with no signal: "PO BOX 1367" -> "BOX1367",
  # "LAS VEGAS" -> "VEGAS", "114 HIGH ST" -> "114HIGHST" (#7). The designator
  # gate is the whole difference between a suite and a city.
  expect_equal(np_unit_id(c("PO BOX 1367", "BOX 19960", "114 HIGH ST", "LAS VEGAS",
                            "C/O JOHN SMITH", "NORTH TOWER", "400891", "STREET")),
               rep(NA_character_, 8))
  # A bare identifier is NA too: a digit string on its own is as often a box
  # number or a record counter as a door. A dedicated unit column does say what
  # it is, and goes to np_extract_unit()'s `unit` argument instead.
  expect_equal(np_unit_id("300"), NA_character_)
  expect_equal(np_extract_unit(NA_character_, "300"), "# 300")
})

test_that("np_extract_unit() reads the unit out of one free-text line", {
  # The public way onto the designator gate: a caller with one address line
  # should not have to normalize a data frame to use it.
  expect_equal(np_extract_unit(c("123 Main St Ste 300", "1180 NORTHERN BLVD - 2ND FL",
                                 "100 CAMPUS CENTER BUILDING 86E", "PO BOX 1558",
                                 "LAS VEGAS", NA)),
               c("STE 300", "FL 2", "BLDG 86E", NA, NA, NA))
  # and it is the street_unit column np_normalize() writes
  d <- np_normalize(np_test_frame(.id = as.character(1:4), name = "ACME FUND",
    street = c("123 Main St Ste 300", "1 A St #300", "PO BOX 1558",
               "100 CAMPUS CENTER BUILDING 86E"), state = "TX"))
  expect_identical(np_extract_unit(d$street), d$street_unit)
})

test_that("np_state_abb() maps names and codes to two letters", {
  expect_equal(np_state_abb(c("Texas", "tx", "DC", "", "Narnia")), c("TX", "TX", "DC", NA, NA))
})
