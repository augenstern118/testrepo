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

analyze_cps <- function(cps, results_dir = "results") {
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  dollar_year <- attr(cps, "latest_dollar_year")
  latest_year <- max(cps$income_year)

  trend <- weighted_summary(cps, income_year, education)

  overall_premium <- trend |>
    dplyr::filter(education %in% c("High school", "Bachelor's")) |>
    dplyr::select(income_year, education, median_weekly) |>
    tidyr::pivot_wider(names_from = education, values_from = median_weekly) |>
    dplyr::mutate(
      premium_pct = 100 * (`Bachelor's` / `High school` - 1)
    )

  by_sex <- weighted_summary(cps, income_year, sex_group, education)

  gender_premium <- by_sex |>
    dplyr::filter(education %in% c("High school", "Bachelor's")) |>
    dplyr::select(income_year, sex_group, education, median_weekly) |>
    tidyr::pivot_wider(names_from = education, values_from = median_weekly) |>
    dplyr::mutate(
      premium_pct = 100 * (`Bachelor's` / `High school` - 1)
    )

  age_profile <- cps |>
    dplyr::filter(income_year == latest_year) |>
    weighted_summary(age_band, education)

  age_premium <- age_profile |>
    dplyr::filter(education %in% c("High school", "Bachelor's")) |>
    dplyr::select(age_band, education, median_weekly) |>
    tidyr::pivot_wider(names_from = education, values_from = median_weekly) |>
    dplyr::mutate(
      premium_pct = 100 * (`Bachelor's` / `High school` - 1)
    )

  palette <- c(
    "High school" = "#4D4D4D",
    "Some college / associate" = "#56B4E9",
    "Bachelor's" = "#0072B2",
    "Advanced degree" = "#D55E00"
  )

  base_theme <- ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey30"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank()
    )

  trend_plot <- ggplot2::ggplot(
    trend,
    ggplot2::aes(income_year, median_weekly, color = education)
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::scale_color_manual(values = palette) +
    ggplot2::scale_y_continuous(labels = scales::label_dollar(accuracy = 1)) +
    ggplot2::scale_x_continuous(breaks = sort(unique(trend$income_year))) +
    ggplot2::labs(
      title = "Education and median weekly earnings",
      subtitle = paste0(
        "Full-time, full-year wage and salary workers ages 25–64; ",
        dollar_year, " dollars"
      ),
      x = NULL,
      y = "Weighted median weekly earnings",
      caption = "Source: IPUMS CPS ASEC. Estimates use ASECWT."
    ) +
    base_theme +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  gender_plot <- ggplot2::ggplot(
    gender_premium,
    ggplot2::aes(income_year, premium_pct, color = sex_group)
  ) +
    ggplot2::geom_hline(yintercept = 0, color = "grey75", linewidth = 0.5) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::geom_point(size = 2.3) +
    ggplot2::scale_color_manual(values = c("Women" = "#CC79A7", "Men" = "#0072B2")) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(scale = 1, accuracy = 1)) +
    ggplot2::scale_x_continuous(breaks = sort(unique(gender_premium$income_year))) +
    ggplot2::labs(
      title = "The bachelor's premium differs for women and men",
      subtitle = "Percent difference in weighted median weekly earnings relative to high-school graduates",
      x = NULL,
      y = "Bachelor's earnings premium",
      caption = "Source: IPUMS CPS ASEC. Estimates use ASECWT."
    ) +
    base_theme +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  age_plot <- ggplot2::ggplot(
    age_profile,
    ggplot2::aes(age_band, median_weekly, color = education, group = education)
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::scale_color_manual(values = palette) +
    ggplot2::scale_y_continuous(labels = scales::label_dollar(accuracy = 1)) +
    ggplot2::labs(
      title = paste0("The education gap changes across the life cycle in ", latest_year),
      subtitle = paste0(
        "Weighted median weekly earnings of full-time, full-year workers; ",
        dollar_year, " dollars"
      ),
      x = "Age group",
      y = "Weighted median weekly earnings",
      caption = "Source: IPUMS CPS ASEC. Estimates use ASECWT."
    ) +
    base_theme

  readr::write_csv(trend, file.path(results_dir, "earnings_by_education.csv"))
  readr::write_csv(overall_premium, file.path(results_dir, "college_premium.csv"))
  readr::write_csv(gender_premium, file.path(results_dir, "college_premium_by_sex.csv"))
  readr::write_csv(age_profile, file.path(results_dir, "earnings_by_age.csv"))

  ggplot2::ggsave(file.path(results_dir, "01_earnings_trend.png"), trend_plot,
                  width = 9, height = 5.2, dpi = 220)
  ggplot2::ggsave(file.path(results_dir, "02_premium_by_sex.png"), gender_plot,
                  width = 9, height = 5.2, dpi = 220)
  ggplot2::ggsave(file.path(results_dir, "03_age_profile.png"), age_plot,
                  width = 9, height = 5.2, dpi = 220)
  writeLines(capture.output(sessionInfo()), file.path(results_dir, "sessionInfo.txt"))

  list(
    trend = trend,
    overall_premium = overall_premium,
    gender_premium = gender_premium,
    age_profile = age_profile,
    age_premium = age_premium,
    trend_plot = trend_plot,
    gender_plot = gender_plot,
    age_plot = age_plot,
    latest_year = latest_year,
    dollar_year = dollar_year
  )
}
