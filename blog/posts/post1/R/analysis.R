# A hypothetical training-program evaluation. No observed microdata are used.
# Run from the website root or from blog/posts/post1; only base R is required.
input_file <- if (file.exists("data/example_inputs.csv")) {
  "data/example_inputs.csv"
} else {
  "blog/posts/post1/data/example_inputs.csv"
}
post_dir <- dirname(dirname(input_file))
inputs <- read.csv(input_file)
results_dir <- file.path(post_dir, "results")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

gain <- inputs$estimate_monthly_usd[1]
standard_error <- inputs$standard_error_usd[1]
cost <- inputs$cost_monthly_usd[1]
confidence_level <- inputs$confidence_level[1]
stopifnot(is.finite(gain), gain > 0, is.finite(standard_error),
          standard_error > 0, is.finite(cost), cost >= 0,
          confidence_level > 0, confidence_level < 1)

# Under the zero-effect null, estimate / known SE follows a standard normal.
# Both tails count because this is a two-sided test.
z_observed <- gain / standard_error
p_value <- 2 * pnorm(-abs(z_observed))
critical_value <- qnorm((1 + confidence_level) / 2)
ci_lower <- gain - critical_value * standard_error
ci_upper <- gain + critical_value * standard_error

summary_results <- data.frame(
  estimate_monthly_usd = gain,
  standard_error_usd = standard_error,
  z_statistic = z_observed,
  p_value = p_value,
  confidence_level = confidence_level,
  ci_lower_usd = ci_lower,
  ci_upper_usd = ci_upper,
  cost_monthly_usd = cost
)
write.csv(summary_results, file.path(results_dir, "summary.csv"), row.names = FALSE)

# Display strings and the blog table are built from the calculated values.
p_text <- sprintf("%.3f", p_value)
tail_percent_text <- sprintf("%.1f", 100 * p_value)
gain_text <- sprintf("%g", gain)
se_text <- sprintf("%g", standard_error)
cost_text <- sprintf("%g", cost)
lower_text <- sprintf("%.0f", ci_lower)
upper_text <- sprintf("%.0f", ci_upper)
display_table <- data.frame(
  measure = c("Estimated wage gain", "Standard error", "Two-sided p-value",
              "95% confidence interval for wage effect", "Assumed program cost"),
  value = c(paste0("$", gain_text), paste0("$", se_text), p_text,
            sprintf("$%.2f to $%.2f", ci_lower, ci_upper), paste0("$", cost_text))
)
write.csv(display_table, file.path(results_dir, "display_table.csv"), row.names = FALSE)

# Save the exact curve data so the figure is reproducible without simulation.
x <- sort(unique(c(seq(-4.5 * standard_error, 4.5 * standard_error,
                       length.out = 2401), -gain, gain)))
density <- dnorm(x, mean = 0, sd = standard_error)
curve_data <- data.frame(estimate_monthly_usd = x, density = density,
                         in_two_sided_tail = abs(x) >= abs(gain))
write.csv(curve_data, file.path(results_dir, "null_curve.csv"), row.names = FALSE)

# Base-R graphic: the tails, rather than a probability for the hypothesis.
png(file.path(results_dir, "null_distribution.png"),
    width = 1800, height = 1100, res = 180, bg = "white")
par(mar = c(5.2, 5.1, 5.4, 1.2), family = "sans", las = 1,
    col.axis = "#374151", col.lab = "#374151", fg = "#374151")
plot(x, density, type = "n", axes = FALSE, ylim = c(0, max(density) * 1.14),
     xlab = "Estimated monthly wage gain (dollars per participant)",
     ylab = "Probability density", cex.lab = 1.05)
abline(h = pretty(c(0, max(density)), n = 4), col = "#E5E7EB")
left_tail <- x <= -gain
right_tail <- x >= gain
polygon(c(x[left_tail], rev(x[left_tail])),
        c(density[left_tail], rep(0, sum(left_tail))),
        col = "#D97706", border = NA)
polygon(c(x[right_tail], rev(x[right_tail])),
        c(density[right_tail], rep(0, sum(right_tail))),
        col = "#D97706", border = NA)
lines(x, density, lwd = 3, col = "#1E3A5F")
segments(c(-gain, gain), 0, c(-gain, gain),
         dnorm(c(-gain, gain), 0, standard_error), col = "#92400E", lty = 2)
axis(1, at = pretty(range(x), n = 8), lwd = 0, lwd.ticks = 1)
axis(2, at = pretty(c(0, max(density)), n = 4), lwd = 0, lwd.ticks = 1)
mtext("If training has no effect, estimates still vary across samples", side = 3,
      line = 3, adj = 0, font = 2, cex = 1.15)
mtext(sprintf("The two shaded tails contain %.1f%% of the null distribution", 100 * p_value),
      side = 3, line = 1.55, adj = 0, cex = 1.03, col = "#92400E")
text(0, max(density) * 1.08, "True effect assumed to be zero", cex = 0.9)
text(c(-gain, gain), max(density) * 0.28,
     labels = c(paste0("-$", gain_text), paste0("+$", gain_text)),
     cex = 0.95, col = "#92400E", pos = c(2, 4))
mtext("Source: hypothetical inputs; normal sampling model; author calculations in R.",
      side = 1, line = 3.9, adj = 0, cex = 0.76, col = "#6B7280")
dev.off()
writeLines(capture.output(sessionInfo()), file.path(results_dir, "sessionInfo.txt"))
