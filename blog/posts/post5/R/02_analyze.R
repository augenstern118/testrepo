# Two comparable choropleths and a component chart form one descriptive story.
analyze_data <- function(prepared) {
  d <- prepared$states
  m <- prepared$map
  palette <- c("Domestic migration" = "#127C8A", "International migration" = "#7566A6",
               "Births minus deaths" = "#C48225", "Residual adjustment" = "#9CA3AF")
  common_theme <- ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 17),
      plot.subtitle = ggplot2::element_text(size = 11),
      plot.caption = ggplot2::element_text(hjust = 0, color = "#526170", size = 9),
      plot.margin = ggplot2::margin(12, 15, 12, 12))
  map_theme <- common_theme + ggplot2::theme(
    axis.title = ggplot2::element_blank(), axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(), panel.grid = ggplot2::element_blank(),
    legend.position = "bottom", legend.key.width = grid::unit(1.1, "cm"))

  # A few labels orient readers. Coordinates are simple bounding-box midpoints;
  # the Florida label is shifted east to keep it on the peninsula.
  shown <- c("CA", "FL", "ID", "NC", "PA", "SC", "TX")
  labels <- do.call(rbind, lapply(shown, function(abbr) {
    z <- m[m$abbreviation == abbr, ]
    data.frame(abbreviation = abbr, x = mean(range(z$x)), y = mean(range(z$y)))
  }))
  labels$x[labels$abbreviation == "FL"] <- labels$x[labels$abbreviation == "FL"] + 190000
  labels$y[labels$abbreviation == "SC"] <- labels$y[labels$abbreviation == "SC"] - 20000
  labels$y[labels$abbreviation == "NC"] <- labels$y[labels$abbreviation == "NC"] + 15000
  labels <- cbind(labels, d[match(labels$abbreviation, d$abbreviation),
                           c("population_change_rate", "domestic_rate")])

  make_map <- function(field, title, subtitle) {
    plot_data <- m
    plot_data$value <- plot_data[[field]]
    label_data <- labels
    label_data$label <- sprintf("%s\n%+.1f", label_data$abbreviation, label_data[[field]])
    ggplot2::ggplot(plot_data, ggplot2::aes(x, y)) +
      ggplot2::geom_polygon(ggplot2::aes(group = fips, subgroup = ring, fill = value),
        rule = "evenodd", color = "white", linewidth = 0.3) +
      ggplot2::geom_text(data = label_data, ggplot2::aes(x, y, label = label),
        inherit.aes = FALSE, size = 3.0, lineheight = 0.9, color = "#172534") +
      ggplot2::coord_fixed() +
      ggplot2::scale_fill_gradient2(low = "#B65F21", mid = "#F0F2F4", high = "#087E8B",
        midpoint = 0, limits = c(-15, 15), breaks = c(-10, -5, 0, 5, 10, 15),
        name = "People per 1,000 residents") + map_theme +
      ggplot2::labs(title = title, subtitle = subtitle,
        caption = paste("July 2024-July 2025; same color scale in both maps. Lower 48 states shown.\n",
          "Source: Census Population Estimates, Vintage 2025; TIGERweb 2024 state boundaries. EPSG:5070."))
  }
  # Fixed scale makes the two maps comparable; validate against silent clipping.
  stopifnot(max(abs(c(d$population_change_rate, d$domestic_rate))) <= 15)
  growth_map <- make_map("population_change_rate", "Population growth concentrates in parts of the South and West",
    "Total population change per 1,000 residents; teal = gain, orange = loss")
  domestic_map <- make_map("domestic_rate", "Domestic migration draws a different map",
    "Net moves within the United States per 1,000 residents; teal = net inflow")

  selected <- c("South Carolina", "Florida", "Pennsylvania", "California")
  cases <- d[match(selected, d$state), ]
  components <- do.call(rbind, lapply(seq_len(nrow(cases)), function(i) {
    data.frame(state = cases$state[i], component = names(palette),
      rate = as.numeric(cases[i, c("domestic_rate", "international_rate", "natural_rate", "residual_rate")]))
  }))
  components$state <- factor(components$state, levels = rev(selected))
  cases$state <- factor(cases$state, levels = rev(selected))
  # Positive bars extend right; negative components extend left. The diamond
  # marks their signed sum, not the end of the positive stack.
  component_plot <- ggplot2::ggplot(components,
      ggplot2::aes(x = state, y = rate, fill = component)) +
    ggplot2::geom_hline(yintercept = 0, color = "#6B7280", linewidth = 0.4) +
    ggplot2::geom_col(width = 0.58) +
    ggplot2::geom_point(data = cases, ggplot2::aes(x = state, y = population_change_rate),
      inherit.aes = FALSE, shape = 23, size = 3.1, fill = "white", color = "#111827") +
    ggplot2::coord_flip() + ggplot2::scale_fill_manual(values = palette, breaks = names(palette)) +
    common_theme + ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(), legend.position = "bottom",
      legend.title = ggplot2::element_blank()) +
    ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2, byrow = TRUE)) +
    ggplot2::labs(title = "Population change has more than one source",
      subtitle = "Change per 1,000 residents, July 2024-July 2025; diamond = total net change",
      x = NULL, y = "Contribution to change (people per 1,000 residents)",
      caption = "Net flows, not gross arrivals. Tiny residual adjustments reconcile the estimates. Source: Census, Vintage 2025.")

  results <- data.frame(
    growing_despite_domestic_loss = sum(d$population_change > 0 & d$domestic < 0),
    states_growing = sum(d$population_change > 0),
    states_analyzed = nrow(d))
  display <- cases[, c("state", "population_change_rate", "domestic_rate", "international_rate", "natural_rate", "residual_rate")]
  names(display) <- c("State", "Total", "Domestic migration", "International migration", "Births minus deaths", "Residual")
  display[-1] <- lapply(display[-1], function(x) sprintf("%+.2f", x))
  write.csv(components, "results/component_chart_data.csv", row.names = FALSE)
  write.csv(display, "results/component_table.csv", row.names = FALSE)
  write.csv(results, "results/summary.csv", row.names = FALSE)
  write.csv(d[order(-d$population_change_rate), ], "results/state_comparison.csv", row.names = FALSE)
  ggplot2::ggsave("results/01_population_growth_map.png", growth_map, width = 10.5, height = 7.1, dpi = 180, bg = "white")
  ggplot2::ggsave("results/02_domestic_migration_map.png", domestic_map, width = 10.5, height = 7.1, dpi = 180, bg = "white")
  ggplot2::ggsave("results/03_growth_components.png", component_plot, width = 10.5, height = 5.6, dpi = 180, bg = "white")
  writeLines(capture.output(sessionInfo()), "results/sessionInfo.txt")
  list(states = d, summary = results, components = components, display = display,
       growth_map = growth_map, domestic_map = domestic_map, component_plot = component_plot)
}
