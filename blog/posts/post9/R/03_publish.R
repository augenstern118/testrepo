forecast_labels <- c(mean = "Historical mean", original = "Classroom XGBoost",
                     revised = "Revised XGBoost")
strategy_labels <- c(spy = "SPY", equal = "Equal weight (95 stocks)", original = "Classroom XGBoost",
                     revised = "Revised XGBoost")
colors <- c(mean = "#545E6B", spy = "#545E6B", equal = "#365A9E", original = "#AC4A24",
            revised = "#08776F")
line_types <- c(spy = 2, equal = 4, original = 3, revised = 1)

forecast_metrics <- function(p) {
  by_day <- split(p, p$signal)
  do.call(rbind, lapply(names(forecast_labels), function(model) {
    # A constant forecast does not produce a stock ranking.
    spearman <- if (model == "mean") NA_real_ else mean(vapply(by_day, function(d) {
      if (length(unique(d[[model]])) < 2) return(0)
      cor(d[[model]], d$actual, method = "spearman")
    }, numeric(1)))
    data.frame(model, rmse = rmse(p$actual, p[[model]]), daily_rank_correlation = spearman)
  }))
}

portfolio_metrics <- function(portfolios) {
  do.call(rbind, lapply(names(strategy_labels), function(strategy) {
    x <- portfolios[portfolios$strategy == strategy, ]
    wealth <- c(100000, x$wealth)
    data.frame(strategy, windows = nrow(x), gross_final = tail(x$gross_wealth, 1),
               net_final = tail(wealth, 1),
               worst_drawdown = min(wealth / cummax(wealth) - 1),
               mean_traded_after_first = mean(x$traded[-1]))
  }))
}

plot_forecasts <- function(metrics) {
  png("results/01_accuracy.png", width = 1250, height = 560, res = 155, bg = "white")
  on.exit(dev.off())
  par(mar = c(4.4, 10.7, 4.2, 1.2), las = 1, col.axis = "#344252")
  x <- 100 * metrics$rmse
  span <- max(diff(range(x)), 0.2)
  plot(x, 3:1, type = "n", yaxt = "n", xaxt = "n", xlab = "", ylab = "",
       ylim = c(0.45, 3.55), xlim = range(x) + c(-0.25, 0.86) * span, bty = "n")
  ticks <- pretty(par("usr")[1:2], n = 6)
  abline(v = ticks, col = "#E0E6EA")
  axis(1, at = ticks, tick = FALSE)
  axis(2, at = 3:1, labels = forecast_labels[metrics$model], tick = FALSE)
  points(x, 3:1, pch = 19, cex = 1.65, col = colors[metrics$model])
  text(x, 3:1, sprintf("%.2f", x), pos = 4, cex = 0.95, col = "#253544")
  mtext("Test RMSE (percentage points)", 1, line = 2.5)
  mtext("How far were the forecasts off?", 3, adj = 0, line = 2.3, font = 2, cex = 1.25)
  mtext("Stock returns from 2024 onward. Lower error is better.", 3, adj = 0,
        line = 0.65, col = "#425363")
}

plot_portfolios <- function(portfolios) {
  png("results/02_wealth.png", width = 1250, height = 720, res = 155, bg = "white")
  on.exit(dev.off())
  par(mar = c(3.7, 5.1, 4.1, 1.3), las = 1, col.axis = "#344252")
  first <- min(portfolios$entry)
  last <- max(portfolios$exit)
  ylim <- range(c(100000, portfolios$wealth))
  plot(c(first, last), ylim, type = "n", yaxt = "n", xaxt = "n", xlab = "",
       ylab = "", bty = "n")
  ticks <- pretty(ylim, n = 6)
  abline(h = ticks, col = "#E0E6EA")
  axis(2, at = ticks, labels = paste0("$", ticks / 1000, "k"), tick = FALSE)
  marks <- seq(as.Date("2024-04-01"), last, by = "6 months")
  axis(1, at = marks, labels = format(marks, "%b %Y"), tick = FALSE)
  for (s in names(strategy_labels)) {
    d <- portfolios[portfolios$strategy == s, ]
    lines(c(first, d$exit), c(100000, d$wealth), col = colors[s], lwd = 2.5,
          lty = line_types[s])
  }
  legend("topleft", legend = strategy_labels, col = colors[names(strategy_labels)],
         lty = line_types, lwd = 2.5, bty = "n", cex = 0.83)
  mtext("What happened to $100,000?", 3, adj = 0, line = 2.2, font = 2, cex = 1.25)
  mtext("Same holding dates, after 10 cents per $100 bought or sold", 3, adj = 0,
        line = 0.65, col = "#425363")
}

publish_article <- function(forecasts, economic, portfolios, grid, game, preds) {
  f <- function(model, column) forecasts[forecasts$model == model, column]
  e <- function(strategy, column) economic[economic$strategy == strategy, column]
  money <- function(n) paste0("$", formatC(round(n), big.mark = ",", format = "d"))
  pc <- function(n) sprintf("%.1f%%", 100 * n)
  strongest <- economic$strategy[which.max(economic$net_final)]
  values <- c(
    GAME_N = game$teams, GAME_WINS = game$indicator_ahead,
    GAME_GAP = money(game$mean_paired_gap_usd),
    TREES = grid$trees, DEPTH = grid$depth,
    NFORECASTS = formatC(nrow(preds), format = "d", big.mark = ","),
    RMSE_MEAN = sprintf("%.2f", 100 * f("mean", "rmse")),
    RMSE_OLD = sprintf("%.2f", 100 * f("original", "rmse")),
    RMSE_NEW = sprintf("%.2f", 100 * f("revised", "rmse")),
    RANK_OLD = sprintf("%.3f", f("original", "daily_rank_correlation")),
    RANK_NEW = sprintf("%.3f", f("revised", "daily_rank_correlation")),
    EQUAL_NET = money(e("equal", "net_final")),
    SPY_NET = money(e("spy", "net_final")), OLD_NET = money(e("original", "net_final")),
    NEW_NET = money(e("revised", "net_final")),
    SPY_GROSS = money(e("spy", "gross_final")), OLD_GROSS = money(e("original", "gross_final")),
    NEW_GROSS = money(e("revised", "gross_final")),
    OLD_DD = pc(abs(e("original", "worst_drawdown"))),
    NEW_DD = pc(abs(e("revised", "worst_drawdown"))),
    SPY_DD = pc(abs(e("spy", "worst_drawdown"))),
    OLD_TURN = pc(e("original", "mean_traded_after_first")),
    NEW_TURN = pc(e("revised", "mean_traded_after_first")),
    BEST_WEALTH = unname(strategy_labels[strongest]),
    WINDOWS = economic$windows[1],
    FIRST_DATE = format(min(portfolios$entry), "%b %d, %Y"),
    LAST_DATE = format(max(portfolios$exit), "%b %d, %Y")
  )
  lines <- readLines("_article-template.qmd", encoding = "UTF-8")
  for (n in names(values)) {
    lines <- gsub(paste0("@@", n, "@@"), values[[n]], lines, fixed = TRUE)
  }
  stopifnot(!any(grepl("@@[A-Z_]+@@", lines)))
  writeLines(enc2utf8(lines), "index.qmd", useBytes = TRUE)
}
