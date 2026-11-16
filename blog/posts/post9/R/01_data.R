# Preserve the classroom formula, including untransformed OHLCV and reversely
# signed lag-price ratios, when constructing the original feature set.
original_features <- c("open", "high", "low", "close", "volume", "adj_close",
                       "daily_return", "mom_1m", "mom_3m", "mom_6m", "vol_1m",
                       "ret_5d", "excess_ret")

revised_features <- c("daily_return", "mom_1m_forward", "mom_3m_forward",
                      "mom_6m_forward", "vol_1m", "ret_5d_forward", "excess_ret",
                      "mom_3m_rank", "vol_rank", "intraday_range",
                      "relative_volume")

build_panel <- function() {
  prices <- read.csv("data/daily_prices.csv.gz")
  prices$date <- as.Date(prices$date)
  tickers <- readLines("data/class_universe.txt")
  spy <- prices[prices$ticker == "SPY", ]
  stopifnot(length(unique(tickers)) == 95, nrow(spy) == 1190,
            identical(spy$date, sort(unique(prices$date))),
            all(is.finite(as.matrix(prices[3:8]))), all(prices$adj_close > 0),
            !anyDuplicated(prices[c("date", "ticker")]))
  calendar <- spy$date
  n <- length(calendar)
  usable <- 127:(n - 20)
  lag_return <- function(p) c(NA_real_, p[-1] / p[-length(p)] - 1)
  market_return <- lag_return(spy$adj_close)
  stocks <- prices[prices$ticker != "SPY", ]
  each <- split(stocks, stocks$ticker)

  panel <- do.call(rbind, lapply(tickers, function(ticker) {
    d <- each[[ticker]]
    stopifnot(identical(d$date, calendar))
    p <- d$adj_close
    j <- usable
    ret <- lag_return(p)
    vol <- vapply(j, function(i) sd(ret[(i - 22):(i - 1)]), numeric(1))
    volume_base <- vapply(j, function(i) median(d$volume[(i - 21):(i - 1)]), numeric(1))
    data.frame(d[j, ], signal = d$date[j], entry = d$date[j + 1],
               exit = d$date[j + 20], entry_idx = j + 1, exit_idx = j + 20,
               signal_idx = j, actual = p[j + 20] / p[j + 1] - 1,
               daily_return = ret[j], excess_ret = ret[j] - market_return[j],
               mom_1m = p[j - 21] / p[j - 1] - 1,
               mom_3m = p[j - 63] / p[j - 1] - 1,
               mom_6m = p[j - 126] / p[j - 1] - 1,
               vol_1m = vol, ret_5d = p[j - 5] / p[j - 1] - 1,
               mom_1m_forward = p[j - 1] / p[j - 21] - 1,
               mom_3m_forward = p[j - 1] / p[j - 63] - 1,
               mom_6m_forward = p[j - 1] / p[j - 126] - 1,
               ret_5d_forward = p[j - 1] / p[j - 5] - 1,
               intraday_range = (d$high[j] - d$low[j]) / d$close[j],
               relative_volume = d$volume[j] / volume_base)
  }))
  panel <- panel[order(panel$signal, match(panel$ticker, tickers)), ]
  rank_pct <- function(x) rank(x, ties.method = "average") / length(x)
  panel$mom_3m_rank <- ave(panel$mom_3m_forward, panel$signal_idx, FUN = rank_pct)
  panel$vol_rank <- ave(panel$vol_1m, panel$signal_idx, FUN = rank_pct)
  stopifnot(all(is.finite(as.matrix(panel[c(original_features, revised_features)]))))
  list(data = panel, prices = each, spy = spy)
}
