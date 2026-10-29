# All observations are SIMULATED hourly wages, not survey or administrative data.
# A lognormal teaching population has known mean $30/hour and log-SD 0.35.
# No empirical calibration or causal claim is intended.
run_simulations <- function() {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  seed <- 20261029L
  population_mean <- 30
  null_mean <- 28
  log_sd <- 0.35
  sizes <- c(30L, 100L, 400L)
  levels <- c(0.90, 0.95)
  B_example <- 4999L
  B_coverage <- 999L
  M <- 1000L
  S <- 10000L
  dir.create("data", showWarnings = FALSE)
  dir.create("results", showWarnings = FALSE)

  # The shift gives the requested arithmetic mean, not the lognormal median.
  draw_wages <- function(n, mean_wage) {
    rlnorm(n, meanlog = log(mean_wage) - log_sd^2 / 2, sdlog = log_sd)
  }
  bootstrap_means <- function(x, B) {
    colMeans(matrix(sample(x, length(x) * B, replace = TRUE), nrow = length(x)))
  }
  interval <- function(means, level) {
    alpha <- 1 - level
    unname(quantile(means, c(alpha / 2, 1 - alpha / 2), type = 7))
  }

  # One original sample; smaller displayed samples use its first n observations.
  set.seed(seed)
  original <- draw_wages(max(sizes), population_mean)
  write.csv(data.frame(worker = seq_along(original), simulated_hourly_wage = original),
            "data/example_sample.csv", row.names = FALSE)

  boot_list <- list()
  coverage_list <- list()
  null_list <- list()
  summary_list <- list()
  test_list <- list()

  for (n in sizes) {
    message("Simulating n = ", n, ": bootstrap, ", M, " new surveys, and null draws.")
    x <- original[seq_len(n)]
    set.seed(seed + n)
    boot <- bootstrap_means(x, B_example)
    boot_list[[as.character(n)]] <- data.frame(n = n, replicate = seq_len(B_example), mean = boot)

    # Each outer iteration starts with a NEW independent population sample.
    # The inner bootstrap estimates that particular sample's interval.
    set.seed(seed + 10000L + n)
    cov <- data.frame(n = n, experiment = seq_len(M), sample_mean = NA_real_,
                      lower90 = NA_real_, upper90 = NA_real_,
                      lower95 = NA_real_, upper95 = NA_real_)
    for (m in seq_len(M)) {
      fresh_sample <- draw_wages(n, population_mean)
      fresh_boot <- bootstrap_means(fresh_sample, B_coverage)
      ci90 <- interval(fresh_boot, 0.90)
      ci95 <- interval(fresh_boot, 0.95)
      cov[m, 3:7] <- c(mean(fresh_sample), ci90, ci95)
    }
    coverage_list[[as.character(n)]] <- cov

    # H0 fully specifies the teaching population: same log-SD, mean $28.
    # A known null SD is used ONLY for this model-based simulation test.
    set.seed(seed + 20000L + n)
    null_sd <- null_mean * sqrt(exp(log_sd^2) - 1)
    null_means <- colMeans(matrix(draw_wages(n * S, null_mean), nrow = n))
    null_z <- (null_means - null_mean) / (null_sd / sqrt(n))
    observed_z <- (mean(x) - null_mean) / (null_sd / sqrt(n))
    null_list[[as.character(n)]] <- data.frame(n = n, simulation = seq_len(S), z = null_z)
    extreme <- sum(abs(null_z) >= abs(observed_z))
    # Plus-one Monte Carlo p-value: a finite simulation never implies p = 0.
    p_value <- (extreme + 1) / (S + 1)
    for (alpha in c(0.01, 0.05, 0.10)) {
      critical <- unname(quantile(abs(null_z), 1 - alpha, type = 7))
      test_list[[length(test_list) + 1L]] <- data.frame(
        n = n, alpha = alpha, null_mean = null_mean, null_sd = null_sd,
        sample_mean = mean(x), observed_z = observed_z, critical_abs_z = critical,
        extreme_count = extreme, null_simulations = S, p_value = p_value,
        reject_by_p = p_value <= alpha
      )
    }

    for (level in levels) {
      suffix <- as.character(round(100 * level))
      lower <- cov[[paste0("lower", suffix)]]
      upper <- cov[[paste0("upper", suffix)]]
      hit <- lower <= population_mean & upper >= population_mean
      coverage <- mean(hit)
      ci <- interval(boot, level)
      summary_list[[length(summary_list) + 1L]] <- data.frame(
        n = n, confidence = level, true_mean = population_mean, sample_mean = mean(x),
        lower = ci[1], upper = ci[2], contains_truth = ci[1] <= population_mean & ci[2] >= population_mean,
        surveys = M, covered = sum(hit), missed = sum(!hit), coverage = coverage,
        coverage_mcse = sqrt(coverage * (1 - coverage) / M),
        mean_width = mean(upper - lower), example_resamples = B_example,
        coverage_resamples = B_coverage
      )
    }
  }
  boot_data <- do.call(rbind, boot_list)
  coverage_data <- do.call(rbind, coverage_list)
  null_data <- do.call(rbind, null_list)
  summary_data <- do.call(rbind, summary_list)
  tests <- do.call(rbind, test_list)
  write.csv(boot_data, "results/bootstrap_draws.csv", row.names = FALSE)
  write.csv(coverage_data, "results/coverage_intervals.csv", row.names = FALSE)
  write.csv(null_data, "results/null_draws.csv", row.names = FALSE)
  write.csv(summary_data, "results/summary.csv", row.names = FALSE)
  write.csv(tests, "results/hypothesis_tests.csv", row.names = FALSE)
  write.csv(data.frame(parameter = c("seed", "population_mean", "null_mean", "log_sd",
                                    "example_resamples", "coverage_resamples", "surveys", "null_simulations"),
                       value = c(seed, population_mean, null_mean, log_sd, B_example, B_coverage, M, S)),
            "data/simulation_parameters.csv", row.names = FALSE)
  stopifnot(nrow(coverage_data) == M * length(sizes),
            all(summary_data$lower < summary_data$upper),
            all(summary_data$covered + summary_data$missed == M),
            all(tests$p_value > 0 & tests$p_value <= 1))
  list(bootstrap = boot_data, coverage = coverage_data, null = null_data,
       summary = summary_data, tests = tests, true_mean = population_mean,
       null_mean = null_mean, sizes = sizes)
}
