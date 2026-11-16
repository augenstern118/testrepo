rmse <- function(actual, prediction) sqrt(mean((actual - prediction)^2))

fit_boost <- function(train, future, features, trees, depth, child_weight) {
  set.seed(123)
  dm <- function(d, training = FALSE) {
    xgboost::xgb.DMatrix(as.matrix(d[features]),
                        label = if (training) d$actual else NULL, nthread = 1)
  }
  model <- xgboost::xgb.train(
    params = list(objective = "reg:squarederror", tree_method = "hist",
                  max_depth = depth, eta = 0.05, gamma = 0,
                  min_child_weight = child_weight, nthread = 1),
    data = dm(train, training = TRUE), nrounds = trees, verbose = 0)
  predict(model, dm(future))
}

fit_models <- function(panel) {
  validation_start <- as.Date("2023-07-01")
  test_start <- as.Date("2024-01-01")
  # Purge labels that would still be unknown at the next split.
  early <- panel[panel$exit < validation_start, ]
  val <- panel[panel$signal >= validation_start & panel$exit < test_start, ]
  train <- panel[panel$exit < test_start, ]
  test <- panel[panel$signal >= test_start, ]
  stopifnot(max(early$exit) < min(val$signal),
            max(train$exit) < min(test$signal),
            max(val$exit) < min(test$signal))
  grid <- expand.grid(depth = 1:3, trees = c(25L, 75L, 150L))
  grid$rmse <- vapply(seq_len(nrow(grid)), function(i) {
    p <- fit_boost(early, val, revised_features, grid$trees[i],
                   grid$depth[i], child_weight = 50)
    rmse(val$actual, p)
  }, numeric(1))
  best <- which.min(grid$rmse)
  grid$selected <- seq_len(nrow(grid)) == best

  out <- test[c("signal", "entry", "exit", "signal_idx", "entry_idx",
                "exit_idx", "ticker", "actual")]
  out$mean <- mean(train$actual)
  out$original <- fit_boost(train, test, original_features, 300L, 5L, 10)
  out$revised <- fit_boost(train, test, revised_features, grid$trees[best],
                           grid$depth[best], 50)
  list(predictions = out, validation = grid, chosen = grid[best, ],
       ranges = data.frame(sample = c("tuning train", "validation", "final train", "test"),
         first_signal = sapply(list(early, val, train, test), function(d) as.character(min(d$signal))),
         last_signal = sapply(list(early, val, train, test), function(d) as.character(max(d$signal))),
         last_exit = sapply(list(early, val, train, test), function(d) as.character(max(d$exit))),
         rows = sapply(list(early, val, train, test), nrow)))
}

backtest <- function(predictions, spy, cost = 0.001, initial = 100000) {
  first <- min(predictions$signal_idx)
  last <- max(predictions$signal_idx)
  # 19 sessions between signals: exit and next entry share the same close.
  signals <- seq(first, last, by = 19)
  periods <- split(predictions[predictions$signal_idx %in% signals, ],
                   predictions$signal_idx[predictions$signal_idx %in% signals])
  do.call(rbind, lapply(c("spy", "equal", "original", "revised"), function(strategy) {
    wealth <- gross_wealth <- initial
    previous <- NULL
    old_weights <- NULL
    runs <- lapply(periods, function(rows) {
      entry <- unique(rows$entry)
      exit <- unique(rows$exit)
      stopifnot(length(entry) == 1, length(exit) == 1,
                is.null(previous) || identical(entry, previous))
      if (strategy == "spy") {
        target <- setNames(1, "SPY")
        realized <- spy$adj_close[rows$exit_idx[1]] / spy$adj_close[rows$entry_idx[1]] - 1
      } else if (strategy == "equal") {
        target <- setNames(rep(1 / nrow(rows), nrow(rows)), rows$ticker)
        realized <- rows$actual
      } else {
        stopifnot(nrow(rows) >= 10)
        chosen <- order(-rows[[strategy]], rows$ticker)[1:10]
        signal <- pmax(0, rows[[strategy]][chosen])
        # Use scalar if/else so the vector isn't recycled (as in ifelse()).
        weights <- if (sum(signal) == 0) rep(0.1, 10) else signal / sum(signal)
        target <- setNames(rep(0, nrow(rows)), rows$ticker)
        target[chosen] <- weights
        realized <- rows$actual
      }
      stopifnot(abs(sum(target) - 1) < 1e-12)
      traded <- if (is.null(old_weights)) 1 else sum(abs(target - old_weights[names(target)]))
      gross <- sum(target * realized)
      net <- (1 - cost * traded) * (1 + gross) - 1
      old_weights <<- target * (1 + realized) / (1 + gross)
      previous <<- exit
      wealth <<- wealth * (1 + net)
      gross_wealth <<- gross_wealth * (1 + gross)
      data.frame(strategy, entry, exit, traded, gross_return = gross, net_return = net,
                 wealth, gross_wealth)
    })
    do.call(rbind, unname(runs))
  }))
}
