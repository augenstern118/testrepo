run_post9 <- function() {
  post <- if (file.exists("blog/posts/post9/R/01_data.R")) "blog/posts/post9" else "."
  if (!file.exists(file.path(post, "R/01_data.R"))) {
    stop("Run from the website root or blog/posts/post9.")
  }
  if (!requireNamespace("xgboost", quietly = TRUE)) {
    stop("The analysis requires the xgboost R package. Rendering the bundled post does not.")
  }
  old <- setwd(post)
  on.exit(setwd(old))
  for (module in c("01_data.R", "02_models.R", "03_publish.R")) {
    source(file.path("R", module), local = TRUE)
  }
  dir.create("results", showWarnings = FALSE)
  built <- build_panel()
  fit <- fit_models(built$data)
  p <- fit$predictions
  b <- backtest(p, built$spy)
  forecast <- forecast_metrics(p)
  economic <- portfolio_metrics(b)
  sensitivity <- do.call(rbind, lapply(c(0, 10, 25), function(bps) {
    data.frame(cost_bps = bps, portfolio_metrics(backtest(p, built$spy, cost = bps / 10000)))
  }))
  game <- read.csv("data/class_game_summary.csv")
  stopifnot(nrow(game) == 1, game$teams == game$indicator_ahead + game$intuition_ahead + game$ties)

  write.csv(fit$validation, "results/validation.csv", row.names = FALSE)
  write.csv(fit$ranges, "results/sample_ranges.csv", row.names = FALSE)
  write.csv(forecast, "results/forecast_metrics.csv", row.names = FALSE)
  write.csv(economic, "results/portfolio_metrics.csv", row.names = FALSE)
  write.csv(b, "results/backtest.csv", row.names = FALSE)
  write.csv(sensitivity, "results/cost_sensitivity.csv", row.names = FALSE)
  con <- gzfile("results/test_predictions.csv.gz", "wt")
  tryCatch(write.csv(p, con, row.names = FALSE), finally = close(con))
  writeLines(c(R.version.string, paste("xgboost", packageVersion("xgboost"))),
             "results/software.txt")
  plot_forecasts(forecast)
  plot_portfolios(b)
  publish_article(forecast, economic, b, fit$chosen, game, p)
  print(forecast, row.names = FALSE)
  print(economic, row.names = FALSE)
}

run_post9()
