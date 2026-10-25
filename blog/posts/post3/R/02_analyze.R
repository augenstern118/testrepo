# Person-level ASEC medians: weights, not observation counts, determine rank.
weighted_median <- function(x, w) {
  keep <- is.finite(x) & is.finite(w) & w > 0
  x <- x[keep]
  w <- w[keep]
  if (length(x) == 0) return(NA_real_)
  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  x[which(cumsum(w) >= sum(w) / 2)[1]]
}

weighted_summary <- function(data, ...) {
  data |>
    dplyr::group_by(...) |>
    dplyr::summarise(
      median_weekly = weighted_median(weekly_earnings, asecwt),
      weighted_population = sum(asecwt),
      observations = dplyr::n(),
      .groups = "drop"
    )
}

# All plots and ratios use these weighted summaries. Keeping this step separate
# also lets a reader check the published calculations from aggregate CSV files.
make_cps_outputs <- function(trend, by_sex, dollar_year, results_dir = "results") {
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  degrees <- c("High school", "Bachelor's")
  first_year <- min(trend$income_year)
  latest_year <- max(trend$income_year)
  if (first_year == latest_year) stop("At least two income years are needed.")

  comparison <- trend |>
    dplyr::filter(education %in% degrees) |>
    dplyr::mutate(education = factor(education, levels = degrees))
  by_sex <- by_sex |>
    dplyr::filter(education %in% degrees) |>
    dplyr::mutate(
      education = factor(education, levels = degrees),
      sex_group = factor(sex_group, levels = c("Women", "Men"))
    ) |>
    dplyr::select(income_year, sex_group, education, median_weekly)

  overall_premium <- comparison |>
    dplyr::select(income_year, education, median_weekly) |>
    tidyr::pivot_wider(names_from = education, values_from = median_weekly) |>
    dplyr::mutate(premium_pct = 100 * (`Bachelor's` / `High school` - 1)) |>
    dplyr::arrange(income_year)

  gender_premium <- by_sex |>
    tidyr::pivot_wider(names_from = education, values_from = median_weekly) |>
    dplyr::mutate(premium_pct = 100 * (`Bachelor's` / `High school` - 1)) |>
    dplyr::arrange(income_year, sex_group)

  overall_change <- comparison |>
    dplyr::group_by(education) |>
    dplyr::summarise(
      first_median = median_weekly[income_year == first_year],
      latest_median = median_weekly[income_year == latest_year],
      .groups = "drop"
    ) |>
    dplyr::mutate(
      first_year = first_year,
      latest_year = latest_year,
      change_pct = 100 * (latest_median / first_median - 1)
    )

  sex_change <- by_sex |>
    dplyr::group_by(sex_group, education) |>
    dplyr::summarise(
      first_median = median_weekly[income_year == first_year],
      latest_median = median_weekly[income_year == latest_year],
      .groups = "drop"
    ) |>
    dplyr::mutate(
      first_year = first_year,
      latest_year = latest_year,
      change_pct = 100 * (latest_median / first_median - 1),
      change_label = sprintf("%+.1f%%", change_pct),
      label_x = change_pct + ifelse(change_pct >= 0, 0.3, -0.3),
      label_hjust = ifelse(change_pct >= 0, 0, 1)
    )

  if (nrow(overall_change) != 2 || nrow(sex_change) != 4 ||
      any(!is.finite(overall_premium$premium_pct)) ||
      any(!is.finite(gender_premium$premium_pct)) ||
      any(!is.finite(overall_change$change_pct)) ||
      any(!is.finite(sex_change$change_pct))) {
    stop("An education/sex comparison is missing. Check the extract.")
  }

  palette <- c("High school" = "#555555", "Bachelor's" = "#0072B2")
  years <- seq(first_year, latest_year, by = 4)
  source_note <- "Source: IPUMS CPS ASEC; author calculations using ASECWT."
  base_theme <- ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(color = "grey30", size = 11),
      plot.caption = ggplot2::element_text(size = 9, hjust = 0),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(12, 16, 12, 12)
    )

  premium_plot <- ggplot2::ggplot(
    overall_premium, ggplot2::aes(income_year, premium_pct)
  ) +
    ggplot2::geom_line(linewidth = 1, color = "#0072B2") +
    ggplot2::geom_point(size = 2.5, color = "#0072B2") +
    ggplot2::scale_x_continuous(breaks = years) +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent(scale = 1, accuracy = 1)
    ) +
    ggplot2::labs(
      title = "The college premium ended modestly higher",
      subtitle = "Bachelor's relative to high school; selected income years",
      x = "Income year", y = "Difference in weighted medians (%)",
      caption = source_note
    ) + base_theme

  earnings_plot <- ggplot2::ggplot(
    comparison, ggplot2::aes(income_year, median_weekly, color = education)
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_color_manual(values = palette) +
    ggplot2::scale_x_continuous(breaks = years) +
    ggplot2::scale_y_continuous(labels = scales::label_dollar(accuracy = 1)) +
    ggplot2::labs(
      title = "Similar endpoints for bachelor's real earnings",
      subtitle = paste0("Full-time, full-year wage workers ages 25–64; ",
                        dollar_year, " dollars"),
      x = "Income year", y = "Weighted median weekly earnings",
      caption = source_note
    ) + base_theme

  # Facets share an axis, so bar lengths are comparable across sex groups.
  change_limits <- range(c(0, sex_change$change_pct)) + c(-2, 2)
  sex_change_plot <- ggplot2::ggplot(
    sex_change, ggplot2::aes(change_pct, education, fill = education)
  ) +
    ggplot2::geom_vline(xintercept = 0, color = "grey50", linewidth = 0.5) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::geom_text(
      ggplot2::aes(x = label_x, label = change_label, hjust = label_hjust),
      size = 3.8, show.legend = FALSE
    ) +
    ggplot2::facet_wrap(~ sex_group, nrow = 1) +
    ggplot2::scale_fill_manual(values = palette) +
    ggplot2::scale_y_discrete(limits = rev(degrees)) +
    ggplot2::scale_x_continuous(
      labels = scales::label_percent(scale = 1, accuracy = 1),
      limits = change_limits
    ) +
    ggplot2::labs(
      title = "Real earnings changes differ within the pooled sample",
      subtitle = paste0("Change in each group's weighted median, ",
                        first_year, "–", latest_year),
      x = "Change in real weekly earnings (%)", y = NULL,
      caption = paste0(source_note, "\nRepeated cross-sections; not individual earnings histories.")
    ) + base_theme + ggplot2::theme(legend.position = "none")

  readr::write_csv(trend, file.path(results_dir, "earnings_by_education.csv"))
  readr::write_csv(by_sex, file.path(results_dir, "earnings_by_sex.csv"))
  readr::write_csv(overall_premium, file.path(results_dir, "college_premium.csv"))
  readr::write_csv(gender_premium, file.path(results_dir, "college_premium_by_sex.csv"))
  readr::write_csv(overall_change, file.path(results_dir, "earnings_change_overall.csv"))
  readr::write_csv(
    dplyr::select(sex_change, -change_label, -label_x, -label_hjust),
    file.path(results_dir, "earnings_change_by_sex.csv")
  )
  ggplot2::ggsave(file.path(results_dir, "01_college_premium.png"), premium_plot,
                  width = 9, height = 5.2, dpi = 220, bg = "white")
  ggplot2::ggsave(file.path(results_dir, "02_real_earnings.png"), earnings_plot,
                  width = 9, height = 5.2, dpi = 220, bg = "white")
  ggplot2::ggsave(file.path(results_dir, "03_earnings_change_by_sex.png"), sex_change_plot,
                  width = 9, height = 5.2, dpi = 220, bg = "white")
  writeLines(capture.output(sessionInfo()), file.path(results_dir, "sessionInfo.txt"))

  list(
    trend = trend, overall_premium = overall_premium,
    gender_premium = gender_premium, overall_change = overall_change,
    sex_change = sex_change, premium_plot = premium_plot,
    earnings_plot = earnings_plot, sex_change_plot = sex_change_plot,
    first_year = first_year, latest_year = latest_year, dollar_year = dollar_year
  )
}

analyze_cps <- function(cps, results_dir = "results") {
  trend <- weighted_summary(cps, income_year, education)
  by_sex <- weighted_summary(cps, income_year, sex_group, education)
  make_cps_outputs(trend, by_sex, attr(cps, "latest_dollar_year"), results_dir)
}
