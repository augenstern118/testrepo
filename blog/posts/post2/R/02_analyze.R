suppressPackageStartupMessages(library(ggplot2))

analyze_careers <- function(careers) {
  dir.create("results", showWarnings = FALSE)
  data <- careers |>
    mutate(
      # These thresholds are an explicit preference scenario, not BLS standards.
      priority_screen = median_pay_usd >= 85000 & growth_pct >= 10 & experience == "None",
      openings_per_100_jobs = 100 * annual_openings / employment
    )
  write_csv(data, "results/career_comparison.csv")
  # Sensitivity analysis prevents treating arbitrary thresholds as universal.
  scenarios <- expand.grid(pay_floor = c(80000, 85000, 90000),
                           growth_floor = c(8, 10, 15))
  sensitivity <- bind_rows(lapply(seq_len(nrow(scenarios)), function(i) {
    s <- scenarios[i, ]
    selected <- data |>
      filter(median_pay_usd >= s$pay_floor, growth_pct >= s$growth_floor,
             experience == "None")
    tibble::tibble(pay_floor = s$pay_floor, growth_floor = s$growth_floor,
      qualifying_paths = if (nrow(selected)) paste(selected$occupation, collapse = "; ") else "None")
  }))
  write_csv(sensitivity, "results/sensitivity.csv")
  year <- unique(data$pay_year)
  period <- paste0(unique(data$projection_start), "-", unique(data$projection_end))
  palette <- c("FALSE" = "#A6B3C2", "TRUE" = "#167D8D")
  chart_theme <- theme_minimal(base_size = 12) +
    theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
          legend.position = "none", plot.title = element_text(face = "bold"),
          plot.caption = element_text(hjust = 0, color = "#526170"),
          plot.margin = margin(12, 28, 12, 12))
  p1 <- ggplot(data, aes(x = reorder(occupation, growth_pct), y = growth_pct,
                         fill = priority_screen)) +
    geom_col(width = 0.62) +
    geom_text(aes(label = paste0(growth_pct, "%")), hjust = -0.2, size = 4) +
    coord_flip() + scale_fill_manual(values = palette) +
    scale_y_continuous(expand = expansion(mult = c(0, .17))) + chart_theme +
    labs(title = "Data science leads on projected growth",
         subtitle = paste("BLS employment projections,", period),
         x = NULL, y = "Projected employment growth (%)",
         caption = "Teal: passes the pay, growth and experience screen. Source: BLS OOH.")
  p2 <- ggplot(data, aes(x = reorder(occupation, annual_openings), y = annual_openings,
                         fill = priority_screen)) +
    geom_col(width = 0.62) +
    geom_text(aes(label = scales::comma(annual_openings)), hjust = -0.1, size = 4) +
    coord_flip() + scale_fill_manual(values = palette) +
    scale_y_continuous(labels = scales::label_comma(), expand = expansion(mult = c(0, .19))) +
    chart_theme + labs(title = "Fast growth and many openings are different",
      subtitle = paste("Projected annual average openings,", period),
      x = NULL, y = "Openings per year (all experience levels)",
      caption = "Openings include replacement needs; these are not current vacancies. Source: BLS OOH.")
  ggsave("results/growth.png", p1, width = 9, height = 4.8, dpi = 180, bg = "white")
  ggsave("results/openings.png", p2, width = 9, height = 4.8, dpi = 180, bg = "white")
  capture.output(sessionInfo(), file = "results/sessionInfo.txt")
  list(data = data, sensitivity = sensitivity, growth_plot = p1, openings_plot = p2)
}
