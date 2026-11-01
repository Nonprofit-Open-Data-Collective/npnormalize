# Which box spellings are worth flagging, measured rather than assumed, and how
# badly the old parse gate misfired. Run against the normalized unified BMF
# (3,687,435 rows, 2,026,583 distinct street strings); re-run it before changing
# .np_box_pat. Modelled on ../npmatch/dev/scan-unit-designators.R, and written
# for issue #9, which asked for exactly this measurement first.
#
# What it showed, and what .np_box_pat is built on:
#
#   * .np_is_pobox() is 579,602 rows (15.718%). Anchoring the box word at the
#     END of the key instead takes it to 591,584 (16.043%) and keeps the
#     implication is_po_box => street_has_box on every row.
#   * The 11,982 rows (0.325%) it adds come in three shapes:
#       - a street then a bare BOX: 562 rows. The reported case --
#         "211 EMMET ST S PO BOX", "FARMERS MERCHANTS TRUST PO BOX" -- where
#         the box number is carried on line 2.
#       - a street then BOX <number>: 10,345 rows, led by
#         "ONE HARRISON PLZ BOX 5079" (652) and "520 N MAIN ST BOX 30" (115).
#       - a lettered box: 1,075 rows, "PO BOX A" through "PO BOX Z".
#         .np_pobox_pat misses these because it requires digits.
#   * DROPPING THE END ANCHOR is the mistake worth measuring. A bare \bBOX\b
#     matches 2,099 rows the anchored form does not, and 127 of them are streets
#     NAMED for a box: BOX SPGS RD, BOX ELDER ST/RD/CIR, BOX RD. The anchored
#     form catches 1 of those 405 rows, "COLLEGEHALL BOXH", which is a box.
#     BOXWOOD, BOXDALE, BOXFORD and BOXER never match either way -- the word
#     boundary alone is enough for them, which is why the guard that matters is
#     the anchor and not a letter class.
#   * An identifier is digits or a SINGLE letter. One letter is the lettered-box
#     family, 1,075 rows of it. Two is the next word of a street name or of a
#     longer label, and the tokens following a BOX the anchor rejects bear that
#     out: SPGS (43 rows), ELDER (32), ONE (28), RD (16), CYN (13).
#   * Designators measured and NOT adopted: DRAWER (55 rows past is_po_box) and
#     BIN (28), both below the volume at which a false positive is already
#     visible -- "1206 GRAIN BIN RD" is in the corpus. POST OFFICE BOX is 0
#     rows: .np_street_types never leaves that spelling standing. LOCKBOX is 2.
#   * The old .np_parse_street() gate, an unanchored grepl("\\bBOX\\b"),
#     treated 593,616 rows as a PO box. 14,014 of them (0.380%) are not one:
#     "ONE HARRISON PLZ BOX 5079" was parsed street_num 5079 on street_name
#     "PO BOX", and "22009 BOX ELDER RD" lost its house number, on a row where
#     is_po_box said FALSE. It now reads .np_is_pobox().

library(npnormalize)
r  <- readRDS("../npmatch/data-dev/NORM-BMF-UNIFIED-v2.rds")$reference
st <- toupper(as.character(r$street)); st[is.na(st)] <- ""
rm(r); gc(FALSE)

# Weight by row, key by distinct string: the street line repeats heavily and
# keying 2.0M strings rather than 3.7M is the difference between minutes.
dt <- data.table::data.table(st = st)[, .(w = .N), by = st]
N  <- length(st); rm(st); gc(FALSE)
u  <- dt$st; w <- dt$w

sk  <- npnormalize:::.np_street_key(u)
pob <- npnormalize:::.np_is_pobox(sk)
bn  <- stringr::str_extract(sk, "[0-9]+")
# np_normalize() publishes the REWRITTEN key, and .np_box_pat is read against
# that, so the scan must rewrite too or the lettered boxes land in the wrong bin.
sk2 <- sk; sk2[pob] <- ifelse(!is.na(bn[pob]), paste("PO BOX", bn[pob]), "PO BOX")

tot <- function(h) sprintf("distinct %7d  rows %8d (%.3f%%)",
                           sum(h), sum(w[h]), 100 * sum(w[h]) / N)
ex  <- function(h, n = 8) {
  i <- which(h); i <- i[order(-w[i])]
  paste(sprintf("%s (%d)", sk2[utils::head(i, n)], w[utils::head(i, n)]),
        collapse = " | ")
}
say <- function(...) { cat(sprintf(...)); flush.console() }

say("rows %d | distinct streets %d | is_po_box %s\n", N, length(u), tot(pob))

# --- 1. which box words are even present, outside the anchored form ----------
say("\n== box words in keys that are NOT is_po_box ==\n")
for (p in list(c("\\bBOX\\b", "BOX"), c("\\bP ?O ?BOX\\b", "PO BOX"),
               c("\\bCAMPUS BOX\\b", "CAMPUS BOX"), c("\\bLOCK ?BOX\\b", "LOCKBOX"),
               c("\\bPOST OFFICE BOX\\b", "POST OFFICE BOX"),
               c("\\bDRAWER\\b", "DRAWER"), c("\\bBIN\\b", "BIN"),
               c("\\bPOB\\b", "POB"), c("\\bPMB\\b", "PMB"))) {
  h <- grepl(p[1], sk2) & !pob
  say("%-16s %s\n                 %s\n", p[2], tot(h), ex(h))
}

# --- 2. where in the key a box word sits, which is what the anchor decides ---
# Gate on .np_has_box, not on \bBOX\b: the key can run the identifier straight
# onto the word ("PO BOX5079"), which has no boundary after BOX, and gating on
# the boundary drops 67 of these rows so the three shapes stop summing to the
# 11,982 section 3 reports.
hb <- npnormalize:::.np_has_box(sk2)
say("\n== what street_has_box adds beyond is_po_box, by shape ==\n")
for (p in list(c("\\bBOX$", "trailing bare BOX"),
               c("\\bBOX ?#? ?[0-9]+$", "BOX <number> at the end"),
               c("\\bBOX ?#? ?[A-Z]$", "BOX <letter> at the end"))) {
  h <- hb & !pob & grepl(p[1], sk2)
  say("%-24s %s\n   %s\n", p[2], tot(h), ex(h))
}
mid <- grepl("\\bBOX\\b", sk2) & !pob & !hb
say("%-24s %s\n   %s\n", "BOX the anchor REJECTS", tot(mid), ex(mid, 12))

say("\n== token following a rejected BOX: a street name, or a box id? ==\n")
nxt <- stringr::str_match(sk2[mid], "\\bBOX ([A-Z0-9]+)")[, 2]
tt  <- sort(tapply(w[mid], ifelse(is.na(nxt), "<end>", nxt), sum), decreasing = TRUE)
print(utils::head(data.frame(after_BOX = names(tt), rows = as.integer(tt)), 30),
      row.names = FALSE)

# --- 3. the candidates, scored on both sides ---------------------------------
# A candidate has to do two things: imply is_po_box, and leave the streets that
# are merely NAMED for a box alone. The second is the one that rules out the
# unanchored form.
say("\n== candidates ==\n")
cand <- list(
  "BOX$, digits only"      = "\\bBOX ?#? ?[0-9]*$",
  "BOX$, digits or 1 ltr"  = "\\bBOX ?#? ?(?:[0-9]+|[A-Z])?$",   # adopted
  "+ DRAWER"               = "\\b(?:BOX|DRAWER) ?#? ?(?:[0-9]+|[A-Z])?$",
  "unanchored BOX"         = "\\bBOX\\b"
)
nmbox <- grepl(paste0("\\bBOX[A-Z]|\\bBOX (ELDER|CANYON|CYN|BUTTE|SPRINGS|SPGS|",
                      "CAR|HILL|TURN|CREEK|RD|ST|DR|AVE|LN)\\b"), sk2)
say("streets NAMED for a box: %s\n   %s\n", tot(nmbox), ex(nmbox, 12))
for (nm in names(cand)) {
  h <- grepl(cand[[nm]], sk2)
  say("\n%-24s %s\n", nm, tot(h))
  say("%-24s is_po_box implied? %s\n", "", if (all(h[pob])) "yes" else "NO")
  say("%-24s beyond is_po_box:  %s\n", "", tot(h & !pob))
  say("%-24s FALSE POSITIVES:   %s\n", "", tot(nmbox & h))
  if (any(nmbox & h)) say("%-24s   %s\n", "", ex(nmbox & h, 10))
}

# --- 4. the parse gate this replaces ----------------------------------------
say("\n== .np_parse_street()'s old gate: grepl(\"\\\\bBOX\\\\b\") ==\n")
old <- grepl("\\bBOX\\b", sk2)
say("treated as a PO box: %s\n", tot(old))
say("  really a box:      %s\n", tot(old & pob))
say("  MISPARSED:         %s\n   %s\n", tot(old & !pob), ex(old & !pob, 12))
