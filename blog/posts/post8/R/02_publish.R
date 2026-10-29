# Build three browser-only Plotly explorers and static figures from R results.
build_outputs <- function(result) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("The analysis requires the jsonlite package in your R environment.")
  }
  hist_values <- function(x, breaks = 35L) {
    h <- hist(x, breaks = breaks, plot = FALSE)
    list(x = h$mids, y = h$counts, width = diff(h$breaks)[1],
         min = min(h$breaks), max = max(h$breaks))
  }
  cases_boot <- list()
  cases_cov <- list()
  cases_null <- list()
  for (n in result$sizes) {
    key <- as.character(n)
    b <- result$bootstrap$mean[result$bootstrap$n == n]
    coverage_n <- result$coverage[result$coverage$n == n, ]
    z <- result$null$z[result$null$n == n]
    s <- result$summary[result$summary$n == n, ]
    t <- result$tests[result$tests$n == n, ]
    cases_boot[[key]] <- list(sampleMean = s$sample_mean[1], resamples = length(b),
      hist = hist_values(b), intervals = list(
        `90` = c(s$lower[s$confidence == 0.90], s$upper[s$confidence == 0.90]),
        `95` = c(s$lower[s$confidence == 0.95], s$upper[s$confidence == 0.95])))
    cases_cov[[key]] <- list(means = coverage_n$sample_mean, lower90 = coverage_n$lower90,
      upper90 = coverage_n$upper90, lower95 = coverage_n$lower95, upper95 = coverage_n$upper95)
    cases_null[[key]] <- list(hist = hist_values(z, breaks = 45L),
      observedZ = t$observed_z[1], extreme = t$extreme_count[1],
      simulations = t$null_simulations[1], p = t$p_value[1],
      tests = data.frame(alpha = t$alpha, critical = t$critical_abs_z))
  }
  template <- paste(readLines("templates/figure.html", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  payloads <- list(
    bootstrap = list(trueMean = result$true_mean, cases = cases_boot),
    coverage = list(trueMean = result$true_mean, cases = cases_cov),
    null = list(trueMean = result$true_mean, cases = cases_null)
  )
  for (kind in names(payloads)) {
    page <- sub("__KIND__", kind, template, fixed = TRUE)
    parts <- strsplit(page, "__PAYLOAD__", fixed = TRUE)[[1]]
    json <- jsonlite::toJSON(payloads[[kind]], auto_unbox = TRUE,
                             dataframe = "rows", digits = NA, null = "null")
    writeLines(paste0(parts[1], json, parts[2]), paste0("results/", kind, ".html"))
  }

  # Static versions show the article's default: n=400, 95%, 1,000 surveys.
  s <- result$summary[result$summary$n == 400 & result$summary$confidence == 0.95, ]
  t <- result$tests[result$tests$n == 400 & result$tests$alpha == 0.05, ]
  boot <- result$bootstrap$mean[result$bootstrap$n == 400]
  cov <- result$coverage[result$coverage$n == 400, ]
  z <- result$null$z[result$null$n == 400]
  png("results/01_bootstrap.png", width = 1800, height = 1050, res = 180, bg = "white")
  par(mar = c(5,5,4,1), las = 1)
  hist(boot, breaks = 35, col = "#93C5FD", border = "white",
       main = "One sample, 4,999 bootstrap means", xlab = "Bootstrap mean hourly wage ($)",
       ylab = "Number of resamples")
  abline(v = c(s$lower, s$upper), col = "#0072B2", lwd = 2)
  abline(v = result$true_mean, col = "#C2410C", lwd = 2, lty = 2)
  legend("topright", c("95% percentile boundaries", "Known population mean: $30"),
         col = c("#0072B2", "#C2410C"), lty = c(1,2), lwd = 2, bty = "n", cex = 0.8)
  mtext("Source: simulated wages; n = 400. No observed worker data.", 1, line = 3.6, cex = 0.75)
  dev.off()

  png("results/02_coverage.png", width = 1800, height = 1150, res = 180, bg = "white")
  par(mar = c(5,5,5,1), las = 1)
  shown <- cov[seq_len(60), ]
  hit <- shown$lower95 <= result$true_mean & shown$upper95 >= result$true_mean
  plot(range(c(shown$lower95, shown$upper95)), c(61,0), ylim = c(61,0), type = "n",
       xlab = "95% interval for mean hourly wage ($)", ylab = "New survey number",
       main = sprintf("%d of 1,000 intervals contain the true mean", s$covered))
  abline(v = result$true_mean, lty = 2, col = "#182B3C", lwd = 2)
  segments(shown$lower95, 1:60, shown$upper95, 1:60,
           col = ifelse(hit, "#0F766E", "#C2410C"), lty = ifelse(hit, 1, 2), lwd = 2)
  mtext("First 60 surveys shown in original order; coverage uses all 1,000.", 3, line = 0.6, cex = 0.85)
  mtext("Source: simulated wages; n = 400. Teal: contains $30; orange: misses $30.",
        1, line = 3.6, cex = 0.75)
  dev.off()

  png("results/03_null_test.png", width = 1800, height = 1050, res = 180, bg = "white")
  par(mar = c(5,5,4,1), las = 1)
  h <- hist(z, breaks = 45, plot = FALSE)
  edge <- max(abs(h$breaks), abs(t$observed_z) + 0.5)
  plot(h, col = "#CBD5E1", border = "white", xlim = c(-edge, edge),
       main = "What would a $28-mean population produce?",
       xlab = "Z = (sample mean - $28) / null standard error", ylab = "Number of null draws")
  usr <- par("usr")
  rect(usr[1], 0, -abs(t$observed_z), usr[4], col = adjustcolor("#FB923C", 0.25), border = NA)
  rect(abs(t$observed_z), 0, usr[2], usr[4], col = adjustcolor("#FB923C", 0.25), border = NA)
  abline(v = c(-t$critical_abs_z,t$critical_abs_z), col = "#7C3AED", lwd = 2, lty = 2)
  abline(v = t$observed_z, col = "#0072B2", lwd = 2)
  legend("topleft", c("Observed Z", "5% rejection cutoffs", "p-value tail regions"),
         col = c("#0072B2", "#7C3AED", "#FB923C"), lty = c(1,2,1), lwd = 2, bty = "n", cex = 0.8)
  mtext("Source: 10,000 simulated null samples; n = 400. Two-sided absolute-Z test.",
        1, line = 3.6, cex = 0.75)
  dev.off()

  # Fill the article from calculated values; no numerical copying is needed.
  small <- result$summary[result$summary$n == 30 & result$summary$confidence == 0.95, ]
  tokens <- c(
    MEAN = sprintf("%.2f", s$sample_mean), LOWER = sprintf("%.2f", s$lower),
    UPPER = sprintf("%.2f", s$upper), COVERED = as.character(s$covered),
    MISSED = as.character(s$missed), COVERAGE = sprintf("%.1f", 100*s$coverage),
    MCSE = sprintf("%.2f", 100*s$coverage_mcse), SMALLCOVER = sprintf("%.1f",100*small$coverage),
    WIDTH = sprintf("%.2f",s$mean_width), SMALLWIDTH = sprintf("%.2f",small$mean_width),
    Z = sprintf("%.2f",t$observed_z), EXTREME = as.character(t$extreme_count),
    P = sprintf("%.4f",t$p_value), CRITICAL = sprintf("%.2f",t$critical_abs_z),
    DECISION = if (t$p_value <= 0.05) "reject" else "do not reject"
  )
  article <- paste(readLines("_article-template.qmd", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  for (name in names(tokens)) {
    article <- gsub(paste0("@@", name, "@@"), tokens[[name]], article, fixed = TRUE)
  }
  if (grepl("@@[A-Z]+@@", article)) stop("Unfilled article value.")
  writeLines(article, "index.qmd")
  writeLines(capture.output(sessionInfo()), "results/sessionInfo.txt")
  invisible(result)
}
