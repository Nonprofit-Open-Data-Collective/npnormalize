# An audit of .np_is_pobox() against the unified BMF, in one pass over the
# corpus. Four questions:
#   A. what spellings does the pattern detect today, in the filer's own words?
#   B. what is it vacuuming up -- detections that are not boxes?
#   C. what is it missing -- box spellings in the corpus it does not detect?
#   D. issue #12: the lettered box and the bare box word, and how many filers
#      each family would have been counted as sharing a building with.
#
# Everything in B and C is read against the RAW street line, not the key: the
# key has already been cleaned and token-replaced, so a variant can only be
# judged against what the filer actually wrote.
#
# What it showed, over 3,687,435 rows / 2,026,583 distinct street strings:
#
#   A. 579,602 rows (15.718%) detected, in four spellings: PO BOX / P O BOX /
#      POBOX 578,684, a bare BOX 682, PO or P O with no box word 164, POB or
#      PO B 72. No other spelling is detected at all -- PB, BX, POSTAL,
#      APARTADO, DRAWER and POST OFFICE BOX are each 0.
#   B. nothing is being vacuumed up. Of 1,000 sampled detections, 0 lack a box
#      word on the raw line; corpus-wide only 30 do, and every one is a box
#      written without a space ("PO762"). The real edge is the dual address
#      line: 1,141 rows carry text after the box number and 136 carry a whole
#      street ("PO BOX 102175 KOOSER RD"), whose street the address-key blank
#      discards. 918 rows rest on a short alternative with no BOX word in the
#      key ("BOX 870136", "P O 17820"); all of them read as boxes.
#   C. the undetected families, in rows: rural route carrying a box 4,625
#      ("RR 1 BOX 8", "HC 81 BOX 363 5"), military PSC/APO/FPO 343, GENERAL
#      DELIVERY 164 (117 of them that exact string), DRAWER 77, MAILBOX 123,
#      MSC / mail stop 432, then a dozen rows or fewer each of PO BX, BX, PB,
#      POSTAL, APARTADO/APDO and BUZON. PMB is 13,700 rows and deliberately
#      not a box: a private mailbox sits at a real street address, which the
#      key keeps. "any BOX, undetected" is 14,015 rows, which is what
#      street_has_box reports.
#   D. the lettered box is 1,010 rows in 41 keys, 982 of them PO BOX A..Z;
#      105 of their 825 address keys hold two or more EINs, up to 15. The bare
#      designator ("PO BOX" and nothing else) is 460 rows in 455 address keys,
#      only 4 of which hold two or more EINs -- so it is not the collapse #12
#      suspected. 0.1.5 acts on the first and leaves the second.
suppressPackageStartupMessages({ library(npnormalize); library(data.table) })

# Where the samples and the cached key table land. Re-keying 2.0M distinct
# street strings is the only slow step, so it is cached: point NP_AUDIT_OUT at
# a durable directory to keep it between runs.
OUT  <- Sys.getenv("NP_AUDIT_OUT", unset = tempdir())
KEYS <- file.path(OUT, "audit-keys.rds")

r  <- readRDS("../npmatch/data-dev/NORM-BMF-UNIFIED-v2.rds")$reference
dt <- data.table(st  = toupper(as.character(r$street)),
                 zip = as.character(r$zip5),
                 ein = as.character(r$.ein))
rm(r); gc(FALSE)
dt[is.na(st), st := ""]; dt[is.na(zip), zip := ""]
N <- nrow(dt)

# Weight by row, key by distinct raw street: 2.0M strings rather than 3.7M, and
# the street key is the only expensive step in the script, so it is cached.
g <- dt[, .(w = .N), by = st]
if (file.exists(KEYS)) {
  cached <- readRDS(KEYS)
  g <- merge(g, cached, by = "st", all.x = TRUE, sort = FALSE)
  if (anyNA(g$sk)) g[is.na(sk), sk := npnormalize:::.np_street_key(st)]
} else {
  g[, sk := npnormalize:::.np_street_key(st)]
  saveRDS(g[, .(st, sk)], KEYS)
}
w   <- g$w
det <- npnormalize:::.np_is_pobox(g$sk)   # what is_po_box reports today

tot <- function(h) sprintf("distinct %7d  rows %8d (%.4f%%)",
                           sum(h), sum(w[h]), 100 * sum(w[h]) / N)
ex  <- function(h, n = 8, col = g$st) {
  i <- which(h); i <- i[order(-w[i])]
  if (!length(i)) return("--")
  paste(sprintf("%s (%d)", col[utils::head(i, n)], w[utils::head(i, n)]),
        collapse = " | ")
}
say   <- function(...) { cat(sprintf(...)); flush.console() }
rule  <- function(t) say("\n\n########## %s ##########\n", t)
dump  <- function(h, n = 40) {
  i <- which(h); i <- i[order(-w[i])]
  print(data.frame(raw = g$st[utils::head(i, n)], key = g$sk[utils::head(i, n)],
                   rows = w[utils::head(i, n)]), row.names = FALSE, right = FALSE)
}

say("rows %d | distinct raw streets %d\n", N, nrow(g))
say("is_po_box today: %s\n", tot(det))

# =========================================================================== A
rule("A. what the pattern detects, by spelling")
# .np_pobox_pat is "^(P ?O ?BOX|P ?O ?B|BOX|P ?O) ?#? ?[0-9]+" on the CLEANED
# key, so these are its alternatives, counted by which one actually fired.
say("the key spelling that matched (first alternative wins):\n")
alts <- list("P O BOX / PO BOX / POBOX" = "^P ?O ?BOX",
             "POB / P O B / PO B"       = "^P ?O ?B(?!OX)",
             "BOX"                      = "^BOX",
             "PO / P O (no box word)"   = "^P ?O ?[0-9#]")
seen <- rep(FALSE, nrow(g))
for (nm in names(alts)) {
  h <- det & !seen & grepl(alts[[nm]], g$sk, perl = TRUE)
  seen <- seen | h
  say("  %-26s %s\n      %s\n", nm, tot(h), ex(h, 6, g$sk))
}
if (any(det & !seen)) say("  %-26s %s\n      %s\n", "UNCLASSIFIED",
                          tot(det & !seen), ex(det & !seen, 6, g$sk))

say("\nthe RAW street spelling behind those detections:\n")
raws <- list(
  "PO BOX"            = "^ *P ?\\.? ?O ?\\.? ?BOX\\b",
  "POBOX (run on)"    = "^ *POBOX",
  "POB / P O B"       = "^ *P ?\\.? ?O ?\\.? ?B\\.? ",
  "POB<digits>"       = "^ *P ?\\.? ?O ?\\.? ?B\\.? ?[0-9]",
  "PB"                = "^ *P ?\\.? ?B\\.?\\b",
  "POST OFFICE BOX"   = "^ *POST ?A?L? ?O?F?F?I?C?E? ?BOX\\b",
  "POSTAL anything"   = "^ *POSTAL\\b",
  "BOX (bare)"        = "^ *BOX\\b",
  "BX"                = "^ *BX\\b",
  "PO <digits>"       = "^ *P ?\\.? ?O ?\\.? ?[0-9]",
  "DRAWER"            = "^ *(P ?\\.? ?O ?\\.? ?)?DRAWER\\b",
  "APARTADO / APDO"   = "^ *AP(AR)?T?DO?\\b",
  "CALLER"            = "^ *CALLER\\b",
  "PMB"               = "^ *PMB\\b",
  "rural route + box" = "^ *(RR|R R|RT|ROUTE|RURAL ROUTE|HC|HCR|STAR ROUTE)\\b.*\\bBOX\\b"
)
for (nm in names(raws)) {
  h <- det & grepl(raws[[nm]], g$st)
  say("  %-20s %s\n", nm, tot(h))
}
oth <- det & !Reduce(`|`, lapply(raws, grepl, x = g$st))
say("  %-20s %s\n", "none of the above", tot(oth))

# =========================================================================== B
rule("B. is anything getting vacuumed up? detections that may not be boxes")
# A generous box alphabet on the raw line. A detection whose raw street has
# none of this is a detection the cleaned key invented.
boxish <- "BOX|^ *P ?\\.? ?O\\b|^ *P ?\\.? ?B\\b|POB|POSTAL|APARTADO|APDO|DRAWER|BUZON"
say("detections with NO box word on the raw line: %s\n", tot(det & !grepl(boxish, g$st)))
dump(det & !grepl(boxish, g$st), 40)

# A box that carries a street as well: blanking the address key costs the
# street, and street_num/street_name take the box number.
trail <- det & grepl("^(P ?O ?BOX|P ?O ?B|BOX|P ?O) ?#? ?[0-9]+ +[A-Z]", g$sk)
say("\ndetections with content AFTER the box number: %s\n", tot(trail))
dump(trail, 30)
stype <- trail & grepl(paste0("\\b(ST|AVE|RD|DR|BLVD|LN|CT|PL|HWY|WAY|TER|CIR|",
                             "PKWY|TRL|PLZ|SQ)$"), g$sk)
say("\n  ...of those, ending in a street type: %s\n", tot(stype))
say("  %s\n", ex(stype, 10, g$sk))

# The short alternatives are the risky ones: no box word at all, just a prefix.
short <- det & grepl("^(P ?O|BOX|P ?O ?B(?!OX)) ?#? ?[0-9]", g$sk, perl = TRUE) &
         !grepl("^P ?O ?BOX", g$sk)
say("\ndetections resting on a short alternative (no BOX word in the key): %s\n",
    tot(short))
dump(short, 30)

# A 1,000-row sample of detections, for eyeballing outside R.
set.seed(20261101)
di <- which(det); s1 <- sample(di, min(1000, length(di)), prob = w[di])
samp1 <- data.frame(raw = g$st[s1], key = g$sk[s1], rows = w[s1],
                    short_alt = short[s1], trailing = trail[s1],
                    no_box_word = !grepl(boxish, g$st[s1]))
data.table::fwrite(samp1, file.path(OUT, "sample-1000-detected.csv"))
say("\n1,000 sampled detections -> sample-1000-detected.csv | flagged: %d short, %d trailing, %d no box word\n",
    sum(samp1$short_alt), sum(samp1$trailing), sum(samp1$no_box_word))

# =========================================================================== C
rule("C. what is it missing? box spellings in the corpus it does not detect")
miss <- list(
  "POST OFFICE BOX"      = "^ *POST ?OFFICE ?BOX\\b",
  "POST BOX / POSTBOX"   = "^ *POST ?BOX\\b",
  "POSTAL <anything>"    = "^ *POSTAL\\b",
  "PB <digits>"          = "^ *P ?\\.? ?B\\.? ?-? ?[0-9]",
  "POB <digits>"         = "^ *P ?\\.? ?O ?\\.? ?B\\.? ?-? ?[0-9]",
  "BX <digits>"          = "^ *BX\\.? ?-? ?[0-9]",
  "PO BX"                = "^ *P ?\\.? ?O ?\\.? ?BX\\b",
  "APARTADO / APDO"      = "^ *AP(AR)?T?DO?\\b",
  "BUZON"                = "^ *BUZON\\b",
  "CALLER (SERVICE)"     = "^ *CALLER\\b",
  "GENERAL DELIVERY"     = "^ *GEN(ERAL)? ?DEL(IVERY)?\\b",
  "DRAWER"               = "\\bDRAWER\\b",
  "LOCKBOX / LOCK BOX"   = "\\bLOCK ?BOX\\b",
  "BIN"                  = "\\bBIN\\b",
  "PMB"                  = "\\bPMB\\b",
  "MSC / MAIL STOP"      = "\\b(MSC|MAIL ?STOP|MAIL ?CODE)\\b",
  "MAILBOX / MAIL BOX"   = "\\bMAIL ?BOX\\b",
  "military (APO/FPO)"   = "\\b(APO|FPO|DPO|PSC|CMR|UNIT [0-9]+ BOX)\\b",
  "rural route + BOX"    = "^ *(RR|R R|RT|ROUTE|RURAL ROUTE|HC|HCR|STAR ROUTE)\\b.*\\bBOX\\b",
  "any BOX, undetected"  = "\\bBOX\\b"
)
for (nm in names(miss)) {
  h <- grepl(miss[[nm]], g$st) & !det
  say("\n%-22s %s\n   %s\n", nm, tot(h), ex(h, 6))
}

# Blind sample: 1,000 undetected rows drawn at random, no pattern applied, so a
# variant nobody thought of has a chance to show up.
ui <- which(!det); s2 <- sample(ui, min(1000, length(ui)), prob = w[ui])
samp2 <- data.frame(raw = g$st[s2], key = g$sk[s2], rows = w[s2])
data.table::fwrite(samp2, file.path(OUT, "sample-1000-undetected.csv"))
say("\n1,000 sampled NON-detections -> sample-1000-undetected.csv\n")
# Print the ones that look mail-ish at all, which is what a human needs to read.
mailish <- grepl(paste0("BOX|BX\\b|^ *P ?\\.? ?O|^ *P ?\\.? ?B|POSTAL|POST ",
                        "|APARTADO|APDO|BUZON|DRAWER|BIN\\b|PMB|CALLER|",
                        "MAIL|^ *(RR|HC|HCR|RT|ROUTE)\\b|DEL\\b"), samp2$raw)
say("of the 1,000, %d carry anything mail-ish:\n", sum(mailish))
print(samp2[mailish, ], row.names = FALSE, right = FALSE, max = 1e5)

# =========================================================================== D
rule("D. issue #12: the lettered box and the bare box word")
HEAD <- "^(P ?O ?BOX|P ?O ?B|BOX|P ?O) ?#? ?"
say("\ncandidate widenings, scored on what they ADD beyond the digits form:\n")
cand <- list("digits, or 1 trailing ltr" = "(?:[0-9]+|[A-Z]$)",
             "single letter, key ends"  = "(?:[0-9]+|[A-Z])$",
             "single letter, own token" = "(?:[0-9]+|[A-Z])\\b",
             "any letters (naive)"      = "(?:[0-9]+|[A-Z]+)")
for (nm in names(cand)) {
  h <- grepl(paste0(HEAD, cand[[nm]]), g$sk)
  say("\n  %-26s %s\n", nm, tot(h))
  say("  %-26s implies the digits form? %s\n", "", if (all(h[det])) "yes" else "NO")
  say("  %-26s ADDS %s\n      %s\n", "", tot(h & !det), ex(h & !det, 12, g$sk))
}

add <- grepl(paste0(HEAD, "(?:[0-9]+|[A-Z])$"), g$sk) & !det
say("\nevery distinct key the strict single-letter form adds, by spelling:\n")
pob_sp <- grepl("^P ?O ?BOX", g$sk)
for (lab in c("PO BOX <letter>", "other spellings")) {
  h <- add & (if (lab == "PO BOX <letter>") pob_sp else !pob_sp)
  say("\n-- %s: %s\n", lab, tot(h))
  i <- which(h); i <- i[order(-w[i])]
  print(data.frame(key = g$sk[i], rows = w[i]), row.names = FALSE, max = 1e5)
}

bare <- grepl(paste0(HEAD, "$"), g$sk)
say("\nthe bare box word -- a key that is the designator and nothing else: %s\n",
    tot(bare))
i <- which(bare); i <- i[order(-w[i])]
print(data.frame(key = g$sk[i], rows = w[i]), row.names = FALSE, max = 1e5)

# How many filers each family would be counted as sharing a building with.
# .np_addr_key() pastes street_key and zip5 and blanks it on .np_pobox_pat, so a
# family that escapes the blank is counted as a building: the harm is distinct
# EINs landing on one such address key.
say("\ndistinct EINs per address key (street_key + zip5), by family:\n")
for (nm in names(list(detected = 1, lettered = 1, bare = 1))) {
  h   <- switch(nm, detected = det, lettered = add, bare = bare)
  sub <- merge(dt, g[h, .(st, sk)], by = "st")
  sub[, akey := paste(sk, zip)]
  a <- sub[, .(eins = uniqueN(ein), rows = .N), by = akey][order(-eins)]
  say("\n  %-9s rows %7d | address keys %6d | with >=2 EINs %6d (%.1f%%) | max %d | rows in a shared key %d\n",
      nm, nrow(sub), nrow(a), sum(a$eins >= 2),
      100 * sum(a$eins >= 2) / nrow(a), max(a$eins), sum(a$rows[a$eins >= 2]))
  print(utils::head(a, 6), row.names = FALSE)
}
say("\ndone\n")
