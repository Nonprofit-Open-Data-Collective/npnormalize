# The corpus statistics and the blocking tokenizer. np_name_freq's test moved
# from npmatch's test-idf.R; the rest are new.

test_that("np_name_freq counts shared name_keys", {
  nf <- np_name_freq(c("ALPHA", "ALPHA", "BETA GAMMA"))
  expect_equal(nf[["ALPHA"]], 2L)
  expect_equal(nf[["BETA GAMMA"]], 1L)
})

test_that("np_token_idf gives a rare token more weight than a common one", {
  idf <- np_token_idf(c("ALPHA FUND", "BETA FUND", "GAMMA FUND", "ALPHA TRUST"))
  expect_gt(idf[["GAMMA"]], idf[["ALPHA"]])
  expect_true(all(is.finite(idf)))
})

test_that("stopwords are uppercase and include the legal forms", {
  sw <- np_stopwords()
  expect_true(all(sw == toupper(sw)))
  expect_true(all(c("INC", "THE") %in% sw))
  expect_false(anyDuplicated(sw) > 0)
})

test_that("np_tokenize() and np_doc_freq() count each token once per row", {
  f <- data.frame(name_key = c("ALPHA BETA", "ALPHA ALPHA", "INC"), stringsAsFactors = FALSE)
  tk <- np_tokenize(f, "name_key", np_stopwords(), 2L, FALSE)
  df <- np_doc_freq(tk$base$row, tk$base$token)
  expect_equal(df[["ALPHA"]], 2)      # rows 1 and 2, the repeat in row 2 counted once
  expect_equal(df[["BETA"]], 1)
  expect_false("INC" %in% names(df))  # a stopword
})
