# Copied unchanged from npmatch@de52bb9 by dev/extract-from-npmatch.R.
# Function names and bodies must not change: the normalizer signature hashes
# them (R/signature.R), and every stored artifact built with it would be
# refused. Comments and roxygen may change; they are not hashed.

# Legal / organizational suffixes. Detected, recorded, and stripped from the
# match key (they inflate similarity between unrelated orgs).
.np_legal_suffixes <- c(
  "INCORPORATED", "INC", "CORPORATION", "CORP", "COMPANY", "CO",
  "LIMITED", "LTD", "LLC", "LLP", "LP", "PC", "PLLC",
  "ASSOCIATION", "ASSN", "ASSOC", "FOUNDATION", "FDN", "FUND",
  "TRUST", "SOCIETY", "INSTITUTE", "ORGANIZATION", "ORG"
)

# Conservative token expansions to a common form (applied whole-word).
.np_abbrev <- c(
  "ASSOC" = "ASSOCIATION", "ASSN" = "ASSOCIATION", "ASSN'" = "ASSOCIATION",
  "NATL" = "NATIONAL", "NAT" = "NATIONAL", "INTL" = "INTERNATIONAL",
  "INTERNATL" = "INTERNATIONAL", "DEPT" = "DEPARTMENT", "DEPT'" = "DEPARTMENT",
  "UNIV" = "UNIVERSITY", "COMM" = "COMMUNITY", "CTR" = "CENTER",
  "CTR'" = "CENTER", "SVCS" = "SERVICES", "SVC" = "SERVICE",
  "AMER" = "AMERICAN", "MT" = "MOUNT", "ST" = "SAINT",
  # Added from networked990's resolver (990 Schedule R / O names), each checked
  # against its contexts in the unified BMF. PHYS was left out on purpose: in
  # the BMF it is mostly PHYS EDUCATION (physical), not PHYSICIANS.
  "FDN" = "FOUNDATION", "FND" = "FOUNDATION", "FNDTN" = "FOUNDATION",
  "FDTN" = "FOUNDATION", "HOSP" = "HOSPITAL", "MED" = "MEDICAL",
  "HLTH" = "HEALTH", "HLTHCARE" = "HEALTHCARE", "MGMT" = "MANAGEMENT",
  "REG" = "REGIONAL", "RGNL" = "REGIONAL", "CNTR" = "CENTER",
  "SYS" = "SYSTEM", "SYST" = "SYSTEM", "SRVCS" = "SERVICES", "SRVS" = "SERVICES"
)

# Tokens dropped anywhere in `name_core`: connector words and legal forms.
# Descriptive organisation words (FOUNDATION, TRUST, ASSOCIATION, FUND, SOCIETY)
# are kept, unlike the trailing-suffix strip that builds `name_key`, because
# "X" and "X FOUNDATION" are usually two different EINs (a charity and its
# fundraising foundation). Taken from networked990's exact-name resolver.
.np_core_stop <- c(
  "THE", "INC", "INCORPORATED", "CORP", "CORPORATION", "CO", "LLC", "LTD",
  "OF", "AND", "A", "AN", "FOR", "LP", "PC", "DBA"
)

# Placeholder text written where a name should be ("SEE SCHEDULE O", "SEE
# ATTACHED", "VARIOUS"), matched on the raw upper-cased name. From 990 filings,
# where preparers write these in name fields.
.np_placeholder_re <- paste0(
  "^\\s*(SEE|REFER TO|PER|AS PER|LISTED ON|LISTED IN)\\s+(THE\\s+)?",
  "(SCHEDULE|SCHED|SCH|ATTACHED|ATTACHMENT|STATEMENT|STMT|PART|LINE|BELOW|",
  "ABOVE|LIST|ADDENDUM|EXHIBIT|SUPPLEMENTAL|FORM)\\b|",
  "^\\s*(VARIOUS|MULTIPLE|SEE ATTACHED|ATTACHED)\\s*$"
)

# A cleaned name made only of these tokens is a placeholder ("N/A", "NONE",
# "SAME AS ABOVE", "NOT APPLICABLE", "UNKNOWN").
.np_placeholder_tok <- c(
  "NA", "N", "A", "NONE", "NO", "X", "SAME", "UNKNOWN", "NOT", "APPLICABLE",
  "SEE", "ABOVE", "AS", "BELOW", "INAPPLICABLE", "NULL"
)

# USPS street-type standardization (long -> short) for address keys.
.np_street_types <- c(
  "STREET" = "ST", "AVENUE" = "AVE", "BOULEVARD" = "BLVD", "ROAD" = "RD",
  "DRIVE" = "DR", "LANE" = "LN", "COURT" = "CT", "PLACE" = "PL",
  "SQUARE" = "SQ", "HIGHWAY" = "HWY", "PARKWAY" = "PKWY", "CIRCLE" = "CIR",
  "TERRACE" = "TER", "TRAIL" = "TRL", "SUITE" = "STE", "APARTMENT" = "APT",
  "BUILDING" = "BLDG", "FLOOR" = "FL", "NORTH" = "N", "SOUTH" = "S",
  "EAST" = "E", "WEST" = "W"
)

# VESTIGIAL. Generation tokens are a person-name concept (Ken Griffey vs Ken
# Griffey Jr) inherited from npmatch's SAM / USASpending person-matching
# lineage. Organisations do not have generations, no veto rule consumes
# name_gen, and it is not a useful feature here -- see ?np_default_rules. The
# extraction is retained only so existing labeled training extracts keep their
# column layout; drop it and name_gen/name_gen_rank together when those are
# regenerated.
#
# Narrowed to abbreviated JR/SR when it was still wired to a veto: spelled-out
# "JUNIOR"/"SENIOR" are ordinary org words ("Junior League", "Senior Care") and
# roman II-V are series/phase numbers ("Fund II", "Phase III"), and both made
# the rule over-fire massively (found via np_veto_audit). The genuinely useful
# organisation-level analogue is the ordinal extractor below (FIRST/SECOND).
.np_generation <- c("JR", "SR")

# Ordinal words <-> a canonical rank, so "FIRST" != "SECOND" can be vetoed.
.np_ordinals <- c(
  "FIRST" = "1", "1ST" = "1", "SECOND" = "2", "2ND" = "2",
  "THIRD" = "3", "3RD" = "3", "FOURTH" = "4", "4TH" = "4",
  "FIFTH" = "5", "5TH" = "5", "SIXTH" = "6", "6TH" = "6",
  "SEVENTH" = "7", "7TH" = "7", "EIGHTH" = "8", "8TH" = "8",
  "NINTH" = "9", "9TH" = "9", "TENTH" = "10", "10TH" = "10"
)

.np_gen_rank <- c(JR = "2", SR = "1")

# Directional words in a name, canonicalized. Word forms only (single letters
# N/S/E/W are usually initials or street directionals, not org descriptors).
# "Southwest X" vs "Southeast X" are different organisations.
.np_directions <- c(
  NORTH = "N", SOUTH = "S", EAST = "E", WEST = "W",
  NORTHEAST = "NE", NORTHWEST = "NW", SOUTHEAST = "SE", SOUTHWEST = "SW"
)

# Recognised trailing street-type tokens (USPS short forms, post-standardization)
# used to split the street name from its type.
.np_street_type_set <- c(
  "ST","AVE","BLVD","RD","DR","LN","CT","PL","SQ","HWY","PKWY","CIR","TER",
  "TRL","WAY","PLZ","LOOP","PATH","PIKE","RUN","ROW","XING","EXPY","FWY",
  "TPKE","ALY","BND","BR","BRG","CYN","CV","CRK","EST","GDNS","GLN","GRN",
  "HTS","HL","HOLW","JCT","KNL","LK","MNR","MDWS","PT","RDG","SPG","SPGS",
  "TRCE","VLY","VW","VIS","WALK","CTR","XRD","PASS","CRES","GTWY","LNDG",
  "MALL","PARK","CMN","CMNS","BLF","CIR"
)

# Full US state / territory name (uppercase) -> USPS two-letter abbreviation.
.np_state_abbr <- c(
  stats::setNames(datasets::state.abb, toupper(datasets::state.name)),
  "DISTRICT OF COLUMBIA" = "DC", "PUERTO RICO" = "PR", "GUAM" = "GU",
  "VIRGIN ISLANDS" = "VI", "U S VIRGIN ISLANDS" = "VI",
  "AMERICAN SAMOA" = "AS", "NORTHERN MARIANA ISLANDS" = "MP"
)

.np_state_codes <- c(datasets::state.abb, "DC", "PR", "GU", "VI", "AS", "MP")

# Latin letters that are not an accented form of some other letter, and the
# ASCII strings they stand for. De-accenting cannot reach them: there is no mark
# to drop, so an unmapped letter survives to the `[^A-Z0-9 ]` rule in
# .np_basic_clean() and is replaced by a SPACE, which splits the word it sits
# in -- "Strasse Fund" came back as "STRA E FUND", "Oresund" as "RESUND".
#
# ICU's Latin-ASCII covers all of these today, so the table is belt and braces
# against an older ICU (eszett is a comparatively recent addition to that
# transform) and, more to the point, it is the list matchdb's `md_light_key()`
# ports into SQL. The two keys must agree character for character or a cached
# reference key and a run-time query key stop meeting, so the mapping is pinned
# here and exposed through np_name_rules() rather than left to the transform.
#
# Written with \u escapes, not literal glyphs, so this file stays pure ASCII.
.np_special_letters <- c(
  "\u00df" = "SS", "\u1e9e" = "SS",    # eszett, capital eszett
  "\u00d8" = "O",  "\u00f8" = "O",     # O with stroke
  "\u0141" = "L",  "\u0142" = "L",     # L with stroke
  "\u0110" = "D",  "\u0111" = "D",     # D with stroke
  "\u00c6" = "AE", "\u00e6" = "AE",    # ash
  "\u0152" = "OE", "\u0153" = "OE",    # ethel
  "\u00de" = "TH", "\u00fe" = "TH"     # thorn
)

.np_tokens <- function(x) strsplit(x, "\\s+")

.np_replace_tokens <- function(x, dict) {
  # A missing value is an empty string, not the token "NA": paste() would turn
  # it into the text "NA", and two records with no street (or no name) would
  # then agree on it.
  x <- as.character(x); x[is.na(x)] <- ""
  toks <- .np_tokens(x)
  vapply(toks, function(tk) {
    hit <- tk %in% names(dict)
    tk[hit] <- dict[tk[hit]]
    paste(tk, collapse = " ")
  }, character(1))
}

# Intra-word punctuation that must be DELETED rather than turned into a space.
#
# The IRS BMF contains no apostrophes or periods at all -- they are stripped
# upstream, and stripped by deletion: "St. Luke's Hospital" is held as
# "ST LUKES HOSPITAL", not "ST LUKE S HOSPITAL". Source datasets keep them
# (3.5% of 990-PF grantee names carry an apostrophe). Turning them into a space
# therefore splits the possessive on the query side only, and no possessive name
# can ever clear an exact-name pass:
#
#   query "BO'S PLACE" -> "BO S PLACE"   vs   BMF "BOS PLACE"   -> no match
#
# Apostrophes are deleted unconditionally. Periods are deleted only between two
# alphanumerics ("F.I.N.D." -> "FIND"), so a period that already separates words
# ("ST. LUKES") still falls through to the space rule below and keeps its break.
#
# The quote class is written with \u escapes rather than literal glyphs so this
# file stays pure ASCII. De-accenting runs before this in .np_basic_clean() and
# already folds the curly forms to a plain apostrophe; the rest are belt and
# braces for any caller that cleans a string directly.
.np_strip_joiners <- function(x) {
  x <- gsub("['\u2018\u2019\u02BC\u00B4`]", "", x, perl = TRUE)
  gsub("(?<=[A-Za-z0-9])\\.(?=[A-Za-z0-9])", "", x, perl = TRUE)
}

# Fold the letters .np_special_letters names to their ASCII spellings.
.np_map_special <- function(x) {
  stringi::stri_replace_all_fixed(x, names(.np_special_letters),
                                  .np_special_letters, vectorize_all = FALSE)
}

# Upper-casing runs AFTER the two folding steps, not before. R's toupper() is
# per-character, so it leaves a letter whose upper case is two letters alone:
# toupper("Strasse") kept the eszett, Latin-ASCII then produced a LOWERCASE
# "ss", and the final [^A-Z0-9 ] rule blanked it -- "STRA E". Folding first and
# upper-casing the result keeps SS / AE / OE / TH (and ligatures such as "fi"),
# and costs nothing otherwise.
.np_basic_clean <- function(x) {
  x <- .np_map_special(as.character(x))
  x <- stringi::stri_trans_general(x, "Latin-ASCII") # de-accent
  x <- toupper(x)
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- .np_strip_joiners(x)          # delete, do not space -- see above
  x <- gsub("[[:punct:]]", " ", x)   # every other mark separates tokens
  x <- gsub("[^A-Z0-9 ]", " ", x)
  stringr::str_squish(x)
}

#' Normalize a query or reference frame
#'
#' Brings entity names and addresses onto a common, matchable form (parity with
#' the BMF `org_name_join` field) and extracts the token-level features the veto
#' layer needs. Adds columns alongside the canonical ones:
#'
#' * `name_key`     cleaned, abbreviation-standardized, legal-suffix-stripped
#' * `dba_key`      the DBA name under the same normalization (for cross-matching)
#' * `name_full`    cleaned name *with* suffix retained
#' * `name_core`    exact-lookup key: `name_full` without connector words and
#'   legal forms anywhere (THE, OF, AND, INC, LLC ...), keeping FOUNDATION,
#'   TRUST, FUND (see [np_name_core()])
#' * `name_placeholder` `TRUE` for names that are not names ("SEE SCHEDULE O",
#'   "N/A", no letters); [npmatch::np_block()] gives such query rows no candidates
#' * `name_form`    detected legal form (INC / LLC / CORP / ...), or `NA`
#' * `name_gen`, `name_gen_rank` **vestigial** — a person-name generation marker
#'   (`JR` / `SR`, ranked `SR` = 1, `JR` = 2) inherited from npmatch's
#'   person-matching lineage. Organisations do not have generations; nothing in
#'   the package consumes these and they are not useful features. Retained only
#'   for column compatibility with existing labeled extracts. See
#'   [npmatch::np_default_rules()].
#' * `name_nums`    space-joined embedded digit tokens (chapter/local numbers)
#' * `name_ord`     canonical ordinal rank(s) found in the name
#' * `street_key`   USPS-standardized street with unit stripped
#' * `street_num`   leading house / box number
#' * `street_name`  street body with the number, type, and unit removed
#' * `street_type`  trailing street type (ST / AVE / BLVD / WAY / ...), or `NA`
#' * `street_unit`  the suite / floor / unit as written, normalized to
#'   "<designator> <id>" ("STE 300", "FL 2", "# 12"). Read from the street line,
#'   or from the `unit` column when the street line names none
#' * `street_unit_id` the identifier alone, separators dropped ("STE D-2" ->
#'   "D2"). Two records are compared on this, so a BMF "STE 300" and a source
#'   "# 300" are recognised as one office
#' * `is_po_box`    `TRUE` if the street *is* a mail receptacle with an
#'   identifier, else `FALSE`. Any spelling of the designator (`PO BOX 12`,
#'   `P O BOX 12`, `POBOX 12`, `POB 12`, `PO B 12`, `PO 12`, `BOX 12`,
#'   `PO BX 12`, `PB 12`, `PB BOX 12`, `P B0X 12`, `POSTAL OFC BOX 12`,
#'   `APDO 12`, `DRAWER B`, `PO DRAWER D`, `POSTAL DRAWER 12`) and any
#'   identifier -- digits, or a single letter where the key ends, so the
#'   lettered boxes `PO BOX A` through `PO BOX Z` count as boxes too. One of
#'   the two gates that blank the address key in [np_addr_key()]
#' * `is_mail_only` `TRUE` if the street names a mail-delivery point that has no
#'   building behind it *and* no identifier this package will reduce to a box:
#'   `GENERAL DELIVERY`, `GEN DEL`, military mail (`PSC 303 BOX 24`,
#'   `CMR 467 BOX 7000`, `APO`, `FPO`, `DPO`) and a university mail drawer
#'   named by two letters (`DRAWER JJ EMORY UNIVERSITY`). The other gate on
#'   [np_addr_key()], and disjoint from `is_po_box` by construction, so the two
#'   flags partition the buildingless addresses. Unlike a box the key is *not*
#'   rewritten, because there is no box number to rewrite it to. A rural route
#'   is deliberately not here: it is a unique delivery point, so `RR 1 BOX 8`
#'   keeps its key, and measured that is safe -- the most crowded
#'   route-with-box address in the BMF holds 5 EINs
#' * `mail_key`     the box plus its ZIP (`"PO BOX 1234 59801"`), or `""` where
#'   the record names no identified box. The complement of the address key:
#'   blanking a box says two filers are not in one building, which is true and
#'   is all it says, while two filers collecting mail from the *same* box are
#'   likely administered by the same people. Weight it by [np_mail_freq()]
#'   before believing it -- one BMF box holds 3,626 EINs. See [np_mail_key()]
#' * `street_has_box` `TRUE` if the street *carries* a box component, whether or
#'   not the whole street is one, so `is_po_box` implies `street_has_box`.
#'   `211 EMMET ST S PO BOX`, `300 KENAN CENTER DR CAMPUS BOX` and
#'   `ONE HARRISON PLZ BOX 5079` are all `TRUE` while `is_po_box` is `FALSE` on
#'   each. Filers write the
#'   street on line 1 and carry the box *number* alone on line 2; this is the
#'   column that says a bare number from that line may be a box rather than a
#'   door. It does not claim that it *is* -- the street can name a suite too
#'   (`4347 W NORTHWEST HWY STE 130 BOX`), and that call belongs to whoever
#'   holds the second line. `street_unit` is not changed by it
#' * `zip5`         five-digit ZIP, leading zeros restored (nested prefix)
#' * `zip3`         three-digit ZIP prefix / SCF region (nested prefix)
#' * `zip9`         full `xxxxx-xxxx` ZIP when the +4 is known, else `NA`
#'
#' The ZIP match hierarchy is the nested prefix family `zip3` \eqn{\subset}
#' `zip5` \eqn{\subset} `zip9`. The +4 add-on (`zip_plus4`) is an input only,
#' consumed to build `zip9`; it is not a standalone level.
#' * `state_abb`    two-letter state code (mapped from a full state name if given)
#'
#' @param data An `np_query` or `np_reference` frame from [npmatch::np_query()] /
#'   [npmatch::np_reference()].
#' @return The same frame with the normalization columns added.
#' @export
np_normalize <- function(data) {
  nm  <- .np_basic_clean(data$name)
  nm  <- .np_replace_tokens(nm, .np_abbrev)

  data$name_gen      <- .np_extract_generation(nm)
  data$name_gen_rank <- unname(.np_gen_rank[data$name_gen])
  data$name_nums     <- .np_extract_numbers(nm)
  data$name_ord      <- .np_extract_ordinals(nm)
  data$name_dir      <- .np_extract_direction(nm)
  data$name_form     <- .np_extract_form(nm)
  data$name_full     <- nm
  # strip a leading "THE" from the match key: it shifts the string and sinks the
  # Jaro-Winkler score (no prefix boost) so "THE X FOUNDATION" would otherwise
  # fail to match "X FOUNDATION" -- a real false negative found in labelling.
  data$name_key      <- .np_strip_lead_the(.np_strip_suffix(nm))
  data$name_core     <- .np_name_core(nm)
  data$name_core[is.na(data$name)] <- ""
  data$name_placeholder <- .np_is_placeholder(data$name, nm)

  # DBA key: same normalization as the name, for exact DBA cross-matching.
  dv <- data$dba; dv[is.na(dv)] <- ""
  data$dba_key <- .np_strip_lead_the(
    .np_strip_suffix(.np_replace_tokens(.np_basic_clean(dv), .np_abbrev)))

  # Division key: a second alternate-name field (SAM's entity_division_name),
  # normalized like the DBA so it can be cross-matched independently.
  dv2 <- if (!is.null(data$division)) as.character(data$division) else
    rep(NA_character_, nrow(data))
  dv2[is.na(dv2)] <- ""
  data$division_key <- .np_strip_lead_the(
    .np_strip_suffix(.np_replace_tokens(.np_basic_clean(dv2), .np_abbrev)))

  data$street_unit <- .np_extract_unit(data$street, data$unit)
  data$street_unit_id <- .np_unit_id(data$street_unit)
  sk  <- .np_street_key(data$street)
  pob <- .np_is_pobox(sk)
  box <- .np_box_identifier(sk)              # a number, or a lettered box's letter
  # Read before the rewrite: a mail-only key is NOT rewritten, so the string
  # the designator was found in is the string that survives.
  mol <- .np_is_mailonly(sk)
  sk[pob] <- ifelse(!is.na(box[pob]), paste("PO BOX", box[pob]), "PO BOX")
  data$street_key <- sk
  data$is_po_box  <- pob
  data$is_mail_only <- mol
  # Read from the rewritten key, so is_po_box implies street_has_box.
  data$street_has_box <- .np_has_box(sk)
  sp <- .np_parse_street(sk)
  data$street_num  <- sp$street_num
  data$street_name <- sp$street_name
  data$street_type <- sp$street_type

  zp <- .np_parse_zip(data$zip5, data$zip_plus4)
  data$zip5 <- zp$zip5
  data$zip3 <- zp$zip3
  data$zip9 <- zp$zip9

  # After the ZIP parse, because the box's ZIP is half the key. Built from the
  # rewritten street_key, which .np_mail_key() is idempotent on.
  data$mail_key <- .np_mail_key(sk, zp$zip5)

  data$state_abb <- .np_to_state_abb(data$state)

  data
}

# Exact-lookup key: the cleaned name without connector words and legal forms
# (see .np_core_stop). Blank when nothing is left.
.np_name_core <- function(nm) {
  out <- vapply(.np_tokens(nm), function(tk)
    paste(tk[nzchar(tk) & !tk %in% .np_core_stop], collapse = " "), character(1))
  out[is.na(nm)] <- ""
  out
}

# TRUE when a name is not usable as a name: blank, placeholder text ("SEE
# SCHEDULE O"), only placeholder tokens ("N/A", "SAME AS ABOVE"), or no letters
# ("100", a misread share). `raw` is the name as written, `nm` the cleaned one.
.np_is_placeholder <- function(raw, nm) {
  raw <- toupper(as.character(raw)); raw[is.na(raw)] <- ""
  nm <- as.character(nm); nm[is.na(nm)] <- ""
  tok <- paste0("(", paste(.np_placeholder_tok, collapse = "|"), ")")
  !grepl("[A-Z]", nm) |
    grepl(.np_placeholder_re, raw, perl = TRUE) |
    grepl(paste0("^", tok, "( ", tok, ")*$"), nm)
}

#' Exact-lookup name key and placeholder check for raw name strings
#'
#' `np_name_core()` cleans a name the way [np_normalize()] does (special
#' letters folded to ASCII, de-accented, upper-cased, `&` to AND, possessives
#' joined, abbreviations expanded), then
#' drops connector words and legal forms anywhere in the name (THE, OF, AND,
#' INC, CORP, LLC ...). Unlike `name_key` it keeps FOUNDATION, TRUST,
#' ASSOCIATION and FUND, so a charity and its foundation get different keys.
#' Use it for exact lookups where a key must point to one organisation.
#'
#' `np_name_placeholder()` is `TRUE` for names that are not names: blank,
#' "SEE SCHEDULE O", "N/A", "SAME AS ABOVE", or no letters at all.
#'
#' @param x Character vector of names as written.
#' @return `np_name_core()`: character vector of keys ("" when nothing is
#'   left). `np_name_placeholder()`: logical vector.
#' @examples
#' np_name_core(c("The Pueblo Zoological Society", "Pueblo Zoological Society Foundation"))
#' np_name_placeholder(c("SEE SCHEDULE O", "N/A", "Acme Fdn"))
#' @export
np_name_core <- function(x) {
  out <- .np_name_core(.np_clean_name(x))
  out[is.na(x)] <- ""      # the cleaner turns NA into the token "NA"
  out
}

#' @rdname np_name_core
#' @export
np_name_placeholder <- function(x) .np_is_placeholder(x, .np_clean_name(x))

# The shared first stage of every name key: clean, then expand abbreviations.
.np_clean_name <- function(x) .np_replace_tokens(.np_basic_clean(x), .np_abbrev)

#' Name-normalization rule tables
#'
#' The tables [np_normalize()] uses, for packages that need the same rules in
#' another engine (for example a DuckDB SQL macro). A port should be checked
#' against [np_name_core()] on test strings; the tables are covered by
#' [np_normalize_signature()].
#'
#' @return A list: `abbrev` (named character, token to expansion),
#'   `core_stop` (tokens dropped from `name_core`), `legal_suffixes`
#'   (trailing tokens stripped from `name_key`), `special_letters` (named
#'   character, a non-decomposable Latin letter to its ASCII spelling, folded
#'   before de-accenting), `placeholder_re` (a Perl regex on the raw
#'   upper-cased name) and `placeholder_tok`.
#' @export
np_name_rules <- function() {
  list(abbrev = .np_abbrev, core_stop = .np_core_stop,
       legal_suffixes = .np_legal_suffixes,
       special_letters = .np_special_letters,
       placeholder_re = .np_placeholder_re, placeholder_tok = .np_placeholder_tok)
}

.np_extract_generation <- function(x) {
  toks <- .np_tokens(x)
  vapply(toks, function(tk) {
    hit <- tk[tk %in% .np_generation]
    if (length(hit)) hit[[1]] else NA_character_
  }, character(1))
}

.np_extract_numbers <- function(x) {
  m <- regmatches(x, gregexpr("[0-9]+", x))
  vapply(m, function(v) if (length(v)) paste(sort(v), collapse = " ") else NA_character_,
         character(1))
}

.np_extract_ordinals <- function(x) {
  toks <- .np_tokens(x)
  vapply(toks, function(tk) {
    hit <- tk[tk %in% names(.np_ordinals)]
    if (length(hit)) paste(sort(unique(.np_ordinals[hit])), collapse = " ")
    else NA_character_
  }, character(1))
}

.np_extract_direction <- function(x) {
  toks <- .np_tokens(x)
  vapply(toks, function(tk) {
    hit <- tk[tk %in% names(.np_directions)]
    if (length(hit)) paste(sort(unique(.np_directions[hit])), collapse = " ")
    else NA_character_
  }, character(1))
}

.np_extract_form <- function(x) {
  toks <- .np_tokens(x)
  vapply(toks, function(tk) {
    hit <- tk[tk %in% .np_legal_suffixes]
    if (length(hit)) .np_canon_form(hit[[length(hit)]]) else NA_character_
  }, character(1))
}

# Collapse synonymous legal forms so INC == INCORPORATED, etc.
.np_canon_form <- function(f) {
  map <- c(INCORPORATED = "INC", CORPORATION = "CORP", COMPANY = "CO",
           LIMITED = "LTD", ASSOCIATION = "ASSN", ASSOC = "ASSN",
           FDN = "FOUNDATION", ORGANIZATION = "ORG")
  ifelse(f %in% names(map), map[f], f)
}

# Drop a single leading "THE " (keeps names like "THEATER" intact).
.np_strip_lead_the <- function(x) {
  out <- sub("^THE ", "", x)
  ifelse(nzchar(out), out, x)          # never blank the whole name
}

.np_strip_suffix <- function(x) {
  toks <- .np_tokens(x)
  out <- vapply(toks, function(tk) {
    keep <- !(tk %in% .np_legal_suffixes)
    # only strip trailing suffixes, keep interior words like "FUND" in a name
    n <- length(tk)
    while (n >= 1 && tk[n] %in% .np_legal_suffixes) n <- n - 1
    paste(tk[seq_len(max(n, 0))], collapse = " ")
  }, character(1))
  out <- stringr::str_squish(out)
  ifelse(out == "", stringr::str_squish(vapply(toks, paste, character(1),
                                               collapse = " ")), out)
}

# Secondary-unit designators and the canonical short form each normalizes to.
# Keys are the spellings that appear in address text, values the USPS
# Publication 28 Appendix C2 abbreviation. The pattern below is built in
# decreasing key length so SUITE wins over STE.
#
# The list is the C2 set filtered against the 1.9M-row unified BMF rather than
# adopted wholesale (dev/scan-unit-designators.R). C2's FRNT, REAR, LOWR, UPPR,
# OFC, PH, PIER, KEY, SIDE and SLIP are left out: in this corpus what they match
# is street names -- PIERCE ST, KEYSER AVE, SIDEHILL RD, N FRNT ST -- not units.
# NO is left out for a sharper reason: it is North far more often than Number
# ("123 NO 5TH ST"), so unlike the others it would delete a real street token.
#
# Every long form whose abbreviation is listed here must be listed BESIDE it,
# because the unit is extracted from the RAW street while .np_street_types
# contracts the long form two lines later in np_normalize(). BUILDING was the
# one key missing its long form, so the two spellings of one address disagreed
# on both outputs: "100 CAMPUS CENTER BUILDING 86E" kept the unit inside
# street_key and recorded no street_unit, while "100 CAMPUS CENTER BLDG 86E"
# stripped it correctly -- so the pair could neither block on street_key nor
# compare on the unit. test-address.R now asserts the general case over
# .np_street_types, because this class of bug is invisible otherwise: the
# street key looks right.
.np_unit_designators <- c(
  SUITE = "STE",   STE  = "STE",   APARTMENT = "APT", APT = "APT",
  UNIT  = "UNIT",  ROOM = "RM",    RM  = "RM",        BLDG = "BLDG",
  BUILDING = "BLDG",
  FLOOR = "FL",    FL   = "FL",    PMB = "PMB",
  SPACE = "SPC",   SPC  = "SPC",   LOT = "LOT",       TRLR = "TRLR",
  DEPT  = "DEPT",  STOP = "STOP",  BSMT = "BSMT",     LBBY = "LBBY",
  HNGR  = "HNGR",  NUMBER = "#",   NUM = "#"
)

# ONE pattern for both extracting the unit and removing it from the street key,
# because two patterns drifted: the extractor allowed "#" and the key strip did
# not, so "123 MAIN ST # 300" recorded unit "# 300" and still keyed as
# "123 MAIN ST 300".
#
# Three guards the old pattern lacked, each measured on the unified BMF:
#
# * A word boundary before the designator. Without it the match ran inside
#   ordinary words -- "SHERMAN WAY" gave RM = "AN WAY", "INDIGO BROOM LOOP" gave
#   RM = "OOM LOOP" and keyed as "10317 INDIGO B". 27,954 rows (11.3% of all
#   extractions) were false this way.
# * A separator before an ALPHABETIC id, which stops a designator that merely
#   starts a word: STERLING, STEWART, WESTERN, VERMONT, BARNSTEAD, UNITY,
#   FLAGLER. In 3,636 rows the false match also MASKED the real unit --
#   "259 N RADNOR CHESTER RD STE 150" extracted "STER", from inside CHESTER.
# * An alphabetic id is a SINGLE letter plus optional digits (STE C, APT D-2,
#   SPC F20, RM C281) and must end on a word boundary. A multi-letter id is
#   almost always the next word of a street name, so "LOCKHART TRLR CT RD" no
#   longer loses "TRLR CT" and "LBBY UNIT" is not a unit called UNIT.
#
# A numeric id may follow with no separator at all ("ROOM216", "STE#12"), which
# is why the alternation splits on whether the id starts with a digit.
.np_unit_pat <- local({
  d  <- names(.np_unit_designators)
  d  <- paste(d[order(-nchar(d))], collapse = "|")
  nm <- "[0-9][0-9A-Z-]*"              # numeric id: 300, 12-B, 216
  al <- "(?:[A-Z][0-9-]*|[A-Z]{2}[0-9][0-9A-Z-]*)"  # C, D-2, F20, C281, NO274
  # Floors are the one designator usually written AFTER the number ("2ND FLOOR",
  # "- 2ND FL"), so they get their own branch, capped at three digits so a
  # stray ZIP at the end of a street line ("... FL 33101") cannot read as a floor.
  paste0("(?:#[ .,]*(?:", nm, "|", al, ")",
         "|\\b[0-9]{1,3}(?:ST|ND|RD|TH)?[ .,-]*(?:FLOOR|FL)",
         "|\\b(?:", d, ")(?:[ .,]*#?[ .,]*", nm, "|[ .,]+#?[ .,]*", al, "))\\b")
})

# One box vocabulary, composed into the patterns below. Nothing downstream
# should hold a copy: np_pattern() hands these strings to a consumer that
# cannot call an R function -- matchdb's DuckDB macros are the reason it exists
# -- so every piece stays inside the regex subset R's own engine and RE2 share.
# No lookaround (TRE rejects it too, without perl = TRUE), no \d, no named
# classes. test-portability.R runs the composed patterns through both engines
# over one fixture and asserts they agree, which is what keeps a SQL copy
# honest rather than merely hand-ported.
#
# Head designators on an already-cleaned street key. A box is a receptacle with
# an IDENTIFIER, which is what separates this list from .np_mail_head below.
# Measured spellings, with their BMF row counts where the family is small:
#   "PO BOX 12" / "P O BOX 12" / "POBOX 12"   578,684 rows
#   "BOX 12"                                      682
#   "PO 12" / "P O 12"                            164
#   "POB 12" / "PO B 12"                           72
#   "PO BX 24514"                                   2   (#13, 0.1.6)
#   "PB 150", "PB BOX 6128"                        12   (#13, 0.1.6)
#   "P B0X 102" -- a zero for the O                 4   (#13, 0.1.6)
#   "POSTAL OFC BOX 54"                             1   (#13, 0.1.6)
#   "APDO 1391"                                     1   (#13, 0.1.6)
#   "DRAWER B", "PO DRAWER D", "POSTAL DRAWER 1549" 53 anchored (#13, 0.1.6)
#
# The drawer prefix group is NON-capturing, and has to stay that way: group 2 of
# .np_pobox_pat is the identifier and matchdb reads it by index in a SQL macro,
# so a capturing group inside the head would silently shift it.
#
# A DRAWER is also in .np_mail_head, which is not redundant: the two lists
# answer different questions. 29 of the 49 anchored drawer keys carry a plain
# identifier and land here ("DRAWER B", "DRAWER 0"); the rest are university
# mail drawers with a two-letter identifier and a name after it ("DRAWER AA
# UNIVERSITY OF MONTEVALLO", "DRAWER JJ EMORY UNIVERSITY"), which no identifier
# pattern should be widened to swallow -- two letters is the next word of a
# street name. Those still have no building, so .np_mail_head blanks them.
.np_box_head <- c("P ?O ?BOX", "P ?O ?BX", "P ?O ?B", "P ?O",
                  "PB BOX", "P ?B[0O]?X", "PB",
                  "POSTAL OFC BOX", "APDO",
                  "(?:P ?O |POST ?OFC |POSTAL )?DRAWER",
                  "BOX")

# A box identifier is digits, or a single letter where the key ENDS. Measured
# over 3,687,435 BMF address strings (dev/audit-pobox.R):
#
#   * digits alone are 579,602 rows (15.718%), in four spellings: PO BOX
#     578,684 rows, a bare BOX 682, PO / P O with no box word 164, POB / PO B
#     72. Nothing else in the corpus is detected -- PB, BX, POSTAL, APARTADO,
#     DRAWER and POST OFFICE BOX are all 0 (see dev/audit-pobox.R section C,
#     and #13 for what that leaves undetected).
#   * a trailing single letter adds 1,010 rows (0.027%) in 41 keys. 982 of them
#     are "PO BOX A" through "PO BOX Z" -- the whole alphabet, led by B (119)
#     and A (116). There is no building at PO BOX Q, but this pattern required
#     digits, so every one escaped the np_addr_key() blank and was counted as a
#     shared building: 105 of their 825 address keys hold two or more EINs, up
#     to 15 at "PO BOX B 75785" (#12).
#   * the other 28 rows are box lines truncated or garbled in the filing --
#     "PO BO", "POB", "BOX R". No street in the corpus has a whole key of a
#     designator followed by one letter.
#   * the letter must be ANCHORED, and only the letter. Unanchored, a single
#     letter as its own token takes those 41 keys to 237, and dropping the
#     anchor entirely reaches "POST OFC" and "PO BO" shapes that are not
#     identifiers at all. A box NUMBER, though, is routinely followed by more
#     text -- 1,141 rows carry a mail stop ("PO BOX 5371 MSC RC 507") and 136
#     carry a street as well -- so anchoring the whole identifier would drop
#     them. The test asserts the widened form still flags every spelling the
#     digits form flagged.
.np_box_id <- "[0-9]+|[A-Z]$"

.np_pobox_pat <- paste0("^(", paste(.np_box_head, collapse = "|"),
                        ") ?#? ?(", .np_box_id, ")")

.np_is_pobox <- function(street_key) {
  s <- toupper(as.character(street_key)); s[is.na(s)] <- ""
  grepl(.np_pobox_pat, s)
}

# Designators that mean "mail is delivered here, nobody works here", with NO
# identifier required. That is the whole difference from .np_box_head: a box
# number can be canonicalized and compared, and these either cannot or must not
# be. The address key blanks on this for the same reason it blanks on a box --
# np_addr_key() answers "same building?", and none of these is a building --
# but the key is NOT rewritten to "PO BOX <id>", because there is no box number
# to put there and throwing the string away would lose the only thing it says.
#
# Measured over 3,687,435 BMF rows (dev/audit-pobox.R section C): 532 rows, 496
# of them invisible to .np_is_pobox.
#
#   * GENERAL DELIVERY 158 rows (117 that exact string, 41 "GEN DEL"). The
#     clearest case in the corpus: the street is the entire address, so every
#     general-delivery filer in a ZIP was being counted as one building's
#     tenants.
#   * military mail 318 rows -- PSC 236, CMR 63, APO 12, FPO 7, DPO 0. Each is
#     an overseas fleet or community mail room, and 290 of them do carry a
#     specific box ("PSC 303 BOX 24"), but the box number is unique only within
#     its PSC, so it is not a np_mail_key() identifier and is deliberately not
#     parsed as one. DPO is in the list at 0 rows because it is the third of the
#     three USPS military designators and a filing will eventually use it.
#   * the drawers with no plain identifier, 20 rows (see .np_box_head).
#
# Why a \b and no identifier: "GEN DEL" cannot run into a street name, since \b
# needs a boundary and "GEN DELANEY ST" has none after DEL. Anchored at ^, none
# of these reaches a street: 0 of the 3,998 rural-route keys, 0 BIN, 0 of the
# BOX ELDER / BOX SPGS family. The one row it takes from a KEEP family is
# "APO MAILBOX 637 REED UN BLDG", which is an APO address.
.np_mail_head <- c("GENERAL DELIVERY", "GEN DEL", "APO", "FPO", "DPO",
                   "PSC", "CMR", "(?:P ?O |POST ?OFC |POSTAL )?DRAWER")

.np_mailonly_pat <- paste0("^(", paste(.np_mail_head, collapse = "|"), ")\\b")

# Reported DISJOINT from is_po_box, so the two flags partition the addresses
# that have no building rather than overlapping on the drawers. A DRAWER sits in
# both vocabularies by design (see .np_box_head), and a caller should not have to
# know that: "DRAWER B" has a comparable identifier and is a box, "DRAWER JJ
# EMORY UNIVERSITY" does not and is mail-only. The address-key blank is the
# UNION either way, which is why np_pattern("mailonly") hands out the raw
# pattern -- a SQL copy ORs the two and lands in the same place.
.np_is_mailonly <- function(street_key) {
  s <- toupper(as.character(street_key)); s[is.na(s)] <- ""
  grepl(.np_mailonly_pat, s) & !grepl(.np_pobox_pat, s)
}

# The identifier out of a box key: the box number, or the single trailing
# letter where that is what the box is called. Both np_normalize()'s "PO BOX
# <id>" rewrite and .np_parse_street()'s street_num read it, so the key and the
# parse cannot disagree about which box this is. Reading only digits here is
# what made the lettered boxes collapse: "PO BOX A" and "PO BOX B" rewrote to
# the same bare "PO BOX", so two different boxes in one ZIP became one address.
.np_box_identifier <- function(street_key) {
  s <- toupper(as.character(street_key)); s[is.na(s)] <- ""
  head_re <- paste0("^(?:", paste(.np_box_head, collapse = "|"), ") ?#? ?")
  # The digits are read from what follows the DESIGNATOR, not from the whole
  # key. Reading the whole key was correct only while no designator contained a
  # digit: "P B0X 102" -- a filer's zero for the O, 4 BMF rows -- took the 0 out
  # of B0X and keyed every one of them to "PO BOX 0", which is the lettered-box
  # collapse of #12 all over again. The digits still need to be found ANYWHERE
  # after the head, because a box number is routinely followed by more text
  # ("PO BOX 102175 KOOSER RD", "PO BOX 5371 MSC RC 507").
  num <- stringr::str_extract(sub(head_re, "", s), "[0-9]+")
  ltr <- stringr::str_match(s, paste0(head_re, "([A-Z])$"))[, 2]
  ifelse(is.na(num), ltr, num)
}

# A box component anywhere on the street, which is a different question from
# .np_is_pobox's "is this street a box" (#9). Filers routinely write the street
# on line 1 ending in the box WORD and carry the box NUMBER alone on line 2, so
# a consumer holding a bare line-2 number has no way to tell a box number from
# a door without this.
#
# The box word must END the key, with at most an identifier after it. Measured
# over 3,687,435 BMF address strings (dev/scan-box-component.R):
#
#   * The anchored form is 16.014% of rows by itself. Ending the key adds
#     11,982 rows (0.325%) that .np_is_pobox does not see, in three shapes:
#     a street then a bare BOX (562 rows -- the reported case,
#     "211 EMMET ST S PO BOX"), a street then BOX <number> (10,345, led by
#     "ONE HARRISON PLZ BOX 5079"), and a lettered box (1,075 -- 982 of them
#     whole-key "PO BOX A" through "PO BOX Z", which .np_pobox_pat missed until
#     0.1.5, and 93 a street then BOX <letter>, "280 SALEM ST BOX B").
#   * Dropping the end anchor -- a bare \bBOX\b -- matches 2,099 rows this does
#     not, and 127 of them are streets NAMED for a box: BOX SPGS RD, BOX ELDER
#     ST, BOX RD. The anchored form catches 1 of those 405 rows
#     ("COLLEGEHALL BOXH", which is a box). BOXWOOD, BOXDALE and BOXFORD never
#     match either way, on the word boundary alone.
#   * An identifier is digits or a SINGLE letter, because that is the whole of
#     the lettered-box family and two letters is the next word of a street name
#     ("BOX RD", "BOX ELDER").
#   * DRAWER and BIN were measured and left out: 55 and 28 rows, against 2
#     false positives already visible at that volume (GRAIN BIN RD). POST
#     OFFICE BOX never survives .np_street_types. LOCKBOX is 2 rows.
#
.np_box_pat <- "\\bBOX ?#? ?(?:[0-9]+|[A-Z])?$"

.np_has_box <- function(street_key) {
  s <- toupper(as.character(street_key)); s[is.na(s)] <- ""
  # A box the head pattern already reports carries one by definition, so the
  # implication is_po_box => street_has_box holds on ANY key rather than only
  # on the rewritten one np_normalize() publishes. "POBOX 12" is why it has to
  # be said out loud: there is no word boundary before BOX, so the tail pattern
  # alone cannot see it, and np_has_box() would answer FALSE for a caller
  # holding the raw line. A consumer can now recompute the flag from a cached
  # street_key in either form.
  grepl(.np_pobox_pat, s) | grepl(.np_box_pat, s)
}

# The unit as written, normalized to "<canonical designator> <id>" ("STE 300",
# "FL 2", "# 12"), or NA when the address names none.
#
# `unit` is the canonical second address line and is consulted only when the
# street line itself carries no unit. Ignoring it was a quiet penalty, not just
# a gap: SAM keeps the suite there (physical_address_line_2) and
# np_detect_geo() selects the street_unit_full profile on that column's
# coverage, so the profile fired *because* the data was present while the
# compared column was NA on every query row -- a unit similarity of 0 on every
# pair. A bare value is accepted from that field ("300", "D-2"), since a
# dedicated unit column needs no designator to say what it is.
.np_extract_unit <- function(street, unit = NULL) {
  s <- toupper(as.character(street)); s[is.na(s)] <- ""
  out <- .np_pick_unit(s)
  if (!is.null(unit)) {
    u <- toupper(stringr::str_squish(as.character(unit))); u[is.na(u)] <- ""
    alt <- .np_pick_unit(u)
    bare <- is.na(alt) & grepl("^[0-9A-Z][0-9A-Z-]*$", u)
    alt[bare] <- .np_norm_unit(paste("#", u[bare]))
    out <- ifelse(is.na(out), alt, out)
  }
  out
}

# How fine-grained each canonical designator is, coarse to fine: a building, an
# area inside it, a door, a mailbox. Every value of .np_unit_designators, plus
# the "#" and postfix "FL" forms .np_norm_unit() writes, must be ranked
# (test-address.R asserts it).
.np_unit_rank <- c(
  BLDG = 1L, HNGR = 1L,
  FL   = 2L, BSMT = 2L, LBBY = 2L, DEPT = 2L, STOP = 2L,
  STE  = 3L, APT  = 3L, UNIT = 3L, RM   = 3L, SPC  = 3L, LOT = 3L, TRLR = 3L,
  `#`  = 3L,
  PMB  = 4L
)

# The ONE unit a line names, where it may name several. Every unit is cut from
# street_key, but street_unit holds one, and taking the first one written threw
# away the one that tells occupants apart: "1 BETHANY RD BUILDING 1 STE 5" kept
# BLDG 1, so every suite in building 1 shared a unit, and
# "2125 BISCAYNE BLVD STE 204 # 22915" kept STE 204, so every mailbox in one
# mail store did. 56,466 of matchdb's 13.0M address strings name two or more.
# The most specific unit wins (.np_unit_rank); between two of one rank the LAST
# wins, because an address is written from the outside in.
.np_pick_unit <- function(s) {
  m <- stringr::str_extract_all(s, .np_unit_pat)
  n <- lengths(m)
  out <- rep(NA_character_, length(s))
  one <- n == 1L
  out[one] <- .np_norm_unit(unlist(m[one], use.names = FALSE))
  for (i in which(n > 1L)) {
    u <- .np_norm_unit(m[[i]])
    u <- u[!is.na(u)]
    if (!length(u)) next
    r <- unname(.np_unit_rank[sub(" .*$", "", u)])
    out[i] <- u[max(which(r == max(r)))]
  }
  out
}

# "Suite 300" / "STE. 300" / "#300" / "ROOM216" -> "STE 300" / "# 300" / "RM 216";
# the postfix floor form "2ND FLOOR" -> "FL 2".
.np_norm_unit <- function(m) {
  post <- grepl("(FLOOR|FL)$", m)
  d  <- stringr::str_extract(m, "^(#|[A-Z]+)")
  id <- .np_unit_id(m)
  id[post] <- stringr::str_extract(m[post], "^[0-9]+")
  # "FL 11TH", "11TH FL" and "FL 11" are one floor
  id <- sub("^([0-9]+)(ST|ND|RD|TH)$", "\\1", id)
  canon <- ifelse(post, "FL",
            ifelse(is.na(d) | d == "#", "#", unname(.np_unit_designators[d])))
  ifelse(is.na(m) | is.na(id) | !nzchar(id), NA_character_, paste(canon, id))
}

# The identifier alone, separators dropped: "STE D-2" -> "D2", "# 300" -> "300".
# This is what two records are compared on, because the designator is spelling
# rather than information: "STE 300", "Suite 300" and "# 300" are one office,
# and a BMF record that writes STE against a SAM record that writes # should not
# read as a conflict.
# The designator a unit id drops, lifted out of .np_unit_id() for the same
# reason as the box vocabulary: matchdb ports it into a DuckDB macro, and
# np_pattern("unit_id") is how it gets it rather than by retyping it.
.np_unit_id_strip <- "^(#|[A-Z]+)[ .,]*#?[ .,]*"

.np_unit_id <- function(x) {
  v  <- toupper(as.character(x))
  id <- sub(.np_unit_id_strip, "", v)
  id <- gsub("[^A-Z0-9]", "", id)
  ifelse(is.na(v) | !nzchar(id), NA_character_, id)
}

.np_street_key <- function(street) {
  # The unit comes out BEFORE cleaning, with the pattern that extracts it: "#"
  # only exists at this point (.np_basic_clean() turns it into a space), which
  # is why the old post-cleaning strip left "123 MAIN ST # 300" keyed as
  # "123 MAIN ST 300".
  s <- toupper(as.character(street))
  s <- gsub(.np_unit_pat, " ", s, perl = TRUE)
  s <- .np_basic_clean(s)
  s <- .np_replace_tokens(s, .np_street_types)
  stringr::str_squish(s)
}

#' Name-key frequency table for a reference corpus
#'
#' Counts how many reference records share each exact `name_key`. A name that
#' occurs once or twice is distinctive (an exact match to it is trustworthy even
#' without address corroboration); a name shared by many records (e.g.
#' "FIRST BAPTIST CHURCH") is not. Used by the distinctive-exact-name promotion
#' in `np_score(method = "hier")`. This is more robust than summed token IDF,
#' which conflates distinctiveness with name length.
#'
#' @param name_keys Character vector of normalized names (reference `name_key`).
#' @return A named integer vector mapping `name_key` -> record count.
#' @export
np_name_freq <- function(name_keys) {
  tab <- table(toupper(as.character(name_keys)))
  stats::setNames(as.integer(tab), names(tab))
}

#' Mail-key frequency table for a reference corpus
#'
#' Counts how many reference records share each exact `mail_key` (box + ZIP).
#' This is what makes a shared box *interpretable* rather than merely true, and
#' it is not an optional refinement — measured over the 3,687,435-row unified
#' BMF, the key separates two populations that want opposite treatment:
#'
#' * **A box shared by two or three filers** is the signal worth having: an
#'   organization and its foundation, a parent and its chapter, a small group of
#'   charities run out of one accountant's office. 30,097 of the 36,910 shared
#'   boxes hold exactly two EINs and 3,829 hold three.
#' * **A box shared by hundreds** is a service bureau and is evidence of
#'   nothing. 678 boxes hold ten or more EINs, and the most crowded —
#'   `PO BOX 653067` in ZIP 75265 — holds **3,626**. Treating that as
#'   common administration would link 3,626 unrelated organizations to each
#'   other.
#'
#' So read `mail_key` as evidence only below a threshold, the same way
#' [np_addr_freq()]'s `share_min` gates an address. Overall: 496,830 distinct
#' mail keys, 7.43% of them shared, and 20.79% of box-holding EINs on a shared
#' box.
#'
#' @param mail_keys Character vector of mail keys (reference `mail_key`), as
#'   built by [np_mail_key()]. Empty strings are dropped, so records that name
#'   no box do not all pile onto one entry.
#' @return A named integer vector mapping `mail_key` -> record count.
#' @seealso [np_mail_key()], [np_addr_freq()]
#' @export
np_mail_freq <- function(mail_keys) {
  v <- toupper(as.character(mail_keys))
  v <- v[!is.na(v) & nzchar(v)]
  tab <- table(v)
  stats::setNames(as.integer(tab), names(tab))
}

#' Address-sharing statistics for a reference corpus
#'
#' Counts how many reference records sit at each exact address, at each address
#' + suite, and how many distinct suites each address carries. This is what
#' makes a suite match *interpretable* rather than merely true:
#'
#' * **One address, many distinct suites** — an office building let to many
#'   nonprofits, common in cities and often a foundation's building rented out
#'   to centralize back-office services. Here the suite is the differentiator,
#'   precisely because an exact-address match surfaces every tenant as a
#'   candidate.
#' * **One address + suite shared by many records** — a fiscal sponsor, a
#'   registered agent, or an accountant's mail drop. The suite is then evidence
#'   of nothing, and the address is worth flagging to a reviewer instead.
#'
#' Feed the result to [npmatch::np_compare()] (`addr_freq =`), which annotates each pair
#' with `addr_shared`, `addr_units`, `addr_unit_shared` and a reviewer-facing
#' `addr_note`, and gates the suite credit in `np_score(method = "hier")`.
#'
#' @param street_keys Normalized street (reference `street_key`).
#' @param zip5 Five-digit ZIP, so one street name in two towns is two addresses.
#' @param unit_ids Normalized unit identifiers (reference `street_unit_id`),
#'   `NA` where a record names no unit.
#' @param name_keys Normalized names (reference `name_key`). Optional, but
#'   without them an address cannot be classified: the share of records
#'   carrying the most common name is what separates a federated parent from a
#'   fiscal sponsor, and counts alone cannot.
#' @param share_min Count above which an address, or an address + suite, counts
#'   as *shared*. Default 10: below that, repeats are usually variants of one
#'   organisation — an org, its foundation, its auxiliary — rather than a
#'   multi-tenant building or a sponsor's mail drop.
#' @param unit_coverage_min Share of the records at an address that must name a
#'   suite before "several distinct suites here" is read as a fact about the
#'   building rather than about the data. Default 0.5.
#' @return An `np_addr_freq` list: `addr` (records per address), `addr_unit`
#'   (records per address + suite), `units` (distinct suites per address),
#'   `unit_coverage`, `n_names`, `top_name_share`, `class` (one of
#'   `"federated"`, `"shared"`, `"building"`, `"cluster"`), `share_min` and
#'   `unit_coverage_min`.
#' @seealso [np_name_freq()], [npmatch::np_compare()]
#' @export
np_addr_freq <- function(street_keys, zip5 = NULL, unit_ids = NULL,
                         name_keys = NULL, share_min = 10L,
                         unit_coverage_min = 0.5) {
  a <- .np_addr_key(street_keys, zip5)
  u <- if (is.null(unit_ids)) rep(NA_character_, length(a)) else as.character(unit_ids)
  ok    <- nzchar(a)
  has_u <- ok & !is.na(u) & nzchar(u)
  addr  <- table(a[ok])
  aunit <- table(paste(a[has_u], u[has_u], sep = "|"))
  units <- tapply(u[has_u], a[has_u], function(v) length(unique(v)))
  n_addr <- stats::setNames(as.integer(addr), names(addr))
  n_unit <- stats::setNames(as.integer(units), names(units))

  # Share of the records at an address that name a suite at all. Without it,
  # "two or more distinct suites here" describes the DATA as easily as the
  # building: at the 4,417 BMF addresses holding 10+ records the share naming a
  # suite has median 0.73 and mean 0.52, and at 1,601 of them not one record
  # names a suite. A suite match is only informative where the reference
  # actually records suites at that address.
  wu  <- stats::setNames(as.integer(table(a[has_u])), names(table(a[has_u])))
  cov <- stats::setNames(rep(0, length(n_addr)), names(n_addr))
  cov[names(wu)] <- wu / n_addr[names(wu)]

  # Distinct names at the address, and the share of records carrying the single
  # most common one. This is what separates the two crowded-address archetypes,
  # which counts alone cannot: a federated parent (3700 GRAND AVE: 5,965
  # records, 45 distinct name_keys, 0.98) against a fiscal sponsor (501
  # SILVERSIDE RD: 1,933 records, 1,931 names, 0.00).
  nk <- if (is.null(name_keys)) NULL else as.character(name_keys)
  if (!is.null(nk)) {
    n_names <- vapply(split(nk[ok], a[ok]), function(v) length(unique(v)), integer(1))
    top_shr <- vapply(split(nk[ok], a[ok]), function(v) max(table(v)) / length(v),
                      numeric(1))
  } else {
    n_names <- stats::setNames(rep(NA_integer_, length(n_addr)), names(n_addr))
    top_shr <- stats::setNames(rep(NA_real_, length(n_addr)), names(n_addr))
  }

  structure(list(
    addr      = n_addr,
    addr_unit = stats::setNames(as.integer(aunit), names(aunit)),
    units     = n_unit,
    unit_coverage  = cov,
    n_names        = n_names[names(n_addr)],
    top_name_share = top_shr[names(n_addr)],
    class     = .np_addr_class(n_addr, n_unit, cov, top_shr[names(n_addr)],
                               share_min, unit_coverage_min),
    share_min = as.integer(share_min),
    unit_coverage_min = as.numeric(unit_coverage_min)), class = "np_addr_freq")
}

# Label an address by what it is, which decides what its evidence is worth.
# Deliberately four coarse labels, each one a different answer to "can this
# address, or a suite within it, separate two candidates":
#
#   federated  many records, one name dominating -- a national office its
#              chapters all file from. The address matches every chapter
#              equally, and so does the suite; the chapter number (name_nums)
#              is the only discriminator, and np_veto() already uses it.
#   shared     many records, many names -- a fiscal sponsor, a registered
#              agent, an accountant. The address is true but uninformative;
#              the NAME does the separating here, which is why damping the
#              address credit measurably does not help (dev note section 9).
#   building   many records across several recorded suites -- the suite is the
#              discriminator, and the only case the suite credit fires in.
#   cluster    a handful of records, usually an org with its foundation or
#              auxiliary. Neither address nor suite helps; the name logic does.
#
# Addresses holding one record are absent from the table entirely -- a lookup
# miss means exactly that, which is 88% of addresses.
.np_addr_class <- function(n_addr, n_unit, cov, top_share, share_min,
                           unit_coverage_min) {
  cls <- rep("cluster", length(n_addr))
  nm  <- names(n_addr)
  big <- n_addr >= share_min
  u   <- n_unit[nm]; u[is.na(u)] <- 0L
  ts  <- top_share[nm]
  cls[big] <- "shared"
  cls[big & u >= 2 & cov[nm] >= unit_coverage_min] <- "building"
  cls[big & !is.na(ts) & ts >= 0.5] <- "federated"
  cls[n_addr < 2] <- "single"
  stats::setNames(cls, nm)
}

# The address a suite is read against: street + ZIP, so "123 MAIN ST" in two
# towns is two addresses.
#
# A mail-delivery address is excluded, because this key answers "same building?"
# and none of them is a building. Leaving one in does not merely add a wrong
# row, it builds a cluster: every box-holder in a ZIP becomes a co-tenant of
# every other, and the address-sharing statistics then read that crowd as an
# office building. Two gates, for the two shapes of the same problem:
# .np_pobox_pat (a receptacle with an identifier) and .np_mailonly_pat (a
# delivery point with none). Together they blank 581,166 of 3,687,435 BMF rows.
#
# What is NOT excluded, deliberately, is a rural route: unlike a box it is a
# unique delivery point, so two filers at "RR 1 BOX 8" in one ZIP really are at
# one place. Measured, that is also safe -- across 4,606 route-with-box address
# keys the most crowded holds 5 EINs, and across 570 bare-route keys, 2. See
# np_mail_key() for the signal a blanked box still carries.
.np_addr_key <- function(street_keys, zip5 = NULL) {
  s <- toupper(as.character(street_keys)); s[is.na(s)] <- ""
  z <- if (is.null(zip5)) rep("", length(s)) else as.character(zip5)
  z[is.na(z)] <- ""
  out <- ifelse(nzchar(s), paste(s, z), "")
  out[grepl(.np_pobox_pat, s) | grepl(.np_mailonly_pat, s)] <- ""
  out
}

# The complement of .np_addr_key(): the box itself, plus ZIP. Blanking a box out
# of the address key says "these two are not in one building", which is true,
# and then says nothing further -- but two organizations collecting mail from
# the SAME box are very likely administered by the same people, which is a
# different claim and a useful one. This key is what carries it.
#
# Only an identified box is keyed. The mail-only designators get "" on purpose:
# "GENERAL DELIVERY 59801" would re-create exactly the false crowd the blank in
# .np_addr_key() just removed, one ZIP's worth of unrelated filers reading as
# one mailbox.
#
# It is idempotent on a rewritten key, which matters because matchdb caches
# street_key and may hand back either form: "POB 25161" and "PO BOX 25161" both
# key to "PO BOX 25161 <zip>".
#
# Measured over the BMF: 580,670 box rows in 496,830 mail keys, 7.43% of which
# are shared by two or more EINs, and 20.79% of box-holding EINs sit on one.
# The count is not optional -- see np_mail_freq(), and the 3,626-EIN box.
.np_mail_key <- function(street_keys, zip5 = NULL) {
  s <- toupper(as.character(street_keys)); s[is.na(s)] <- ""
  z <- if (is.null(zip5)) rep("", length(s)) else as.character(zip5)
  z[is.na(z)] <- ""
  out <- character(length(s))
  if (!length(s)) return(out)              # ifelse() here returned logical(0)
  z   <- rep_len(z, length(s))             # recycled explicitly, because the
  id  <- .np_box_identifier(s)             # box rows are then indexed, not
  box <- .np_is_pobox(s) & !is.na(id)      # pasted whole
  out[box] <- paste("PO BOX", id[box], z[box])
  out
}

#' @export
print.np_addr_freq <- function(x, ...) {
  cat("<np_addr_freq>\n")
  cat(sprintf("  addresses: %d | with a suite: %d | shared above: %d\n",
              length(x$addr), length(x$units), x$share_min))
  if (!is.null(x$class)) {
    tb <- table(x$class)
    cat(sprintf("  %s\n", paste(sprintf("%s %d", names(tb), tb), collapse = " | ")))
  }
  invisible(x)
}

#' Per-token inverse document frequency for a reference corpus
#'
#' Document frequency of each name token across the reference, turned into
#' `idf = log(N / df)`: rare tokens (distinctive, high IDF) are the ones the
#' name-token blocking leverages; corpus-common tokens (low IDF) are not. Feed
#' the result to [npmatch::np_route()] (`token_idf =`) to annotate the tokenized name
#' fields with each token's rarity, exposing which tokens carry the match.
#'
#' @param name_keys Character vector of normalized names (reference `name_key`).
#' @param stopwords Tokens to drop (see [np_stopwords()]).
#' @param min_token_len Minimum token length to count. Default 2.
#' @return A named numeric vector mapping token -> IDF.
#' @export
np_token_idf <- function(name_keys, stopwords = np_stopwords(), min_token_len = 2L) {
  v <- as.character(name_keys); v[is.na(v)] <- ""
  toks <- strsplit(toupper(v), "\\s+")
  ut <- lapply(toks, function(t)
    unique(t[nchar(t) >= min_token_len & !(t %in% stopwords)]))
  df <- table(unlist(ut, use.names = FALSE))
  idf <- log(length(v) / as.numeric(df))
  stats::setNames(idf, names(df))
}

# Parse a ZIP field into the nested prefix family zip5 / zip3 / zip9, restoring
# dropped leading zeros. Handles 5-digit, 9-digit (with or without a dash), and
# short (leading-zero-dropped) inputs. The +4 add-on is used internally to build
# zip9 (falling back to a separately mapped `zip_plus4` column) but is not
# returned as a standalone level.
.np_parse_zip <- function(zip_raw, zip_plus4_raw = NULL) {
  d <- gsub("[^0-9]", "", as.character(zip_raw))
  n <- nchar(d)
  base <- ifelse(n > 5, substr(d, 1, n - 4), d)          # 5-digit portion
  p4d  <- ifelse(n > 5, substr(d, n - 3, n), NA_character_)
  z5   <- ifelse(n > 0, stringr::str_pad(substr(base, 1, 5), 5, "left", "0"),
                 NA_character_)

  p4m <- if (is.null(zip_plus4_raw)) rep(NA_character_, length(d))
         else gsub("[^0-9]", "", as.character(zip_plus4_raw))
  p4m <- ifelse(!is.na(p4m) & nzchar(p4m),
                stringr::str_pad(substr(p4m, 1, 4), 4, "left", "0"), NA_character_)
  p4 <- ifelse(!is.na(p4d), p4d, p4m)                    # +4 add-on (internal)

  z3 <- ifelse(!is.na(z5), substr(z5, 1, 3), NA_character_)
  z9 <- ifelse(!is.na(z5) & !is.na(p4), paste0(z5, "-", p4), NA_character_)
  data.frame(zip5 = z5, zip3 = z3, zip9 = z9, stringsAsFactors = FALSE)
}

# Split a cleaned street key into number / name / type. PO boxes are recognised:
# the box number becomes street_num and street_name is "PO BOX".
.np_parse_street <- function(street_key) {
  sk <- toupper(as.character(street_key)); sk[is.na(sk)] <- ""
  # A box is the ANCHORED form, the one is_po_box reports -- not any BOX
  # anywhere. The old unanchored test overwrote the parse of 14,014 BMF rows
  # (0.380%) whose street merely carries or is named for a box: it gave
  # "ONE HARRISON PLZ BOX 5079" street_num 5079 on street_name "PO BOX", and
  # "22009 BOX ELDER RD" lost its house number to street_name "PO BOX" while
  # is_po_box said FALSE on the same row. See .np_box_pat for the measurement
  # and for street_has_box, which is how a caller asks the other question.
  is_po <- .np_is_pobox(sk)
  # The house number is a whole leading token. Without the lookahead an ordinal
  # street was read as one: "16TH ST" gave street_num "16T" and street_name "H",
  # and "6TH AND CHESTNUT ST" gave "6T" and "H AND CHESTNUT". The grid numbers
  # of northern Illinois and southern Wisconsin ("16W540 BLUFF RD", "0S064
  # KERRY CT") are one house number, which the old rule cut to "16W".
  # A number run into the street name ("921AIRPORT SERVICE RD", which gave
  # "921A") is the digits alone, unless they could begin an ordinal.
  num  <- "^[0-9]+([NSEW][0-9]+)?[A-Z]?(-[0-9]+[A-Z]?)?(?= |$)"
  glue <- "^[0-9]+(?=[A-Z]{2})(?!(ST|ND|RD|TH))"
  lead <- stringr::str_extract(sk, num)
  lead <- ifelse(is.na(lead), stringr::str_extract(sk, glue), lead)
  rest <- ifelse(is.na(lead), sk, stringr::str_squish(substring(sk, nchar(lead) + 1L)))
  # The same identifier the key is rewritten with, so street_num names the box
  # the key names. The old regex required the literal word BOX, so the POB and
  # "PO <n>" spellings -- 236 BMF rows, keyed as "PO BOX <n>" like any other --
  # lost their box number to NA.
  box  <- .np_box_identifier(sk)

  nm_ty <- t(vapply(rest, function(r) {
    if (!nzchar(r)) return(c(NA_character_, NA_character_))
    tk <- strsplit(r, " ")[[1]]; L <- length(tk)
    if (L >= 2 && tk[L] %in% .np_street_type_set)
      c(paste(tk[-L], collapse = " "), tk[L])
    else if (L == 1 && tk %in% .np_street_type_set)
      c(NA_character_, tk)
    else c(r, NA_character_)
  }, character(2)))

  street_num  <- lead
  street_name <- nm_ty[, 1]
  street_type <- nm_ty[, 2]
  street_num[is_po]  <- box[is_po]
  street_name[is_po] <- "PO BOX"
  street_type[is_po] <- NA_character_
  data.frame(street_num = unname(street_num), street_name = unname(street_name),
             street_type = unname(street_type), stringsAsFactors = FALSE)
}

# Map a state value to its two-letter code: pass through valid codes, translate
# full names, otherwise NA.
.np_to_state_abb <- function(state) {
  s <- toupper(stringr::str_squish(as.character(state)))
  out <- ifelse(s %in% .np_state_codes, s, unname(.np_state_abbr[s]))
  out[!nzchar(s)] <- NA_character_
  out
}
