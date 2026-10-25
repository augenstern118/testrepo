# A single Plotly time series. Independent controls update either y values or
# trace visibility, so changing units does not erase an industry selection.
pct_values <- lapply(metadata$series_id, function(id) employment$change_pct[employment$series_id == id])
job_values <- lapply(metadata$series_id, function(id) employment$change_thousands[employment$series_id == id])
contrast_ids <- c("PAYEMS", "USMINE", "USPBS", "USEHS", "USLAH")
overview_visibility <- lapply(metadata$series_id, function(id) if (id %in% contrast_ids) TRUE else "legendonly")
goods_visibility <- lapply(metadata$series_id, function(id) if (id %in% c("PAYEMS", "USMINE", "USCONS", "MANEMP")) TRUE else "legendonly")
all_visibility <- rep(list(TRUE), nrow(metadata))

explorer <- plotly::plot_ly(height = 920)
for (i in seq_len(nrow(metadata))) {
  d <- employment[employment$series_id == metadata$series_id[i], ]
  # Tooltip always reports both measures, regardless of the selected y axis.
  hover <- paste0(
    "<b>", d$sector, "</b><br>",
    paste(month.abb[as.integer(format(d$date, "%m"))], format(d$date, "%Y")),
    "<br>Payroll jobs: ", format(d$jobs_thousands * 1000, big.mark = ",", scientific = FALSE, trim = TRUE),
    "<br>Change: ", ifelse(d$change_pct >= 0, "+", "-"),
    formatC(abs(d$change_pct), format = "f", digits = 1, decimal.mark = "."), "%",
    "<br>Jobs gained/lost: ", ifelse(d$change_thousands >= 0, "+", "-"),
    format(abs(d$change_thousands) * 1000, big.mark = ",", scientific = FALSE, trim = TRUE),
    "<br>vs February 2020"
  )
  explorer <- plotly::add_trace(
    explorer, x = d$date, y = d$change_pct, name = metadata$sector[i],
    type = "scatter", mode = "lines", text = hover, hoverinfo = "text",
    line = list(color = metadata$color[i], width = if (metadata$kind[i] == "total") 3.5 else 2.2,
                dash = if (metadata$kind[i] == "total") "dash" else "solid"),
    visible = overview_visibility[[i]], connectgaps = FALSE
  )
}

explorer <- plotly::layout(
  explorer, autosize = TRUE,
  font = list(family = "Arial, sans-serif", size = 12, color = "#253347"),
  paper_bgcolor = "white", plot_bgcolor = "white",
  margin = list(l = 70, r = 15, t = 130, b = 330, autoexpand = FALSE),
  hovermode = "closest", dragmode = "zoom",
  xaxis = list(title = "", type = "date", tickformat = "%Y", dtick = "M12",
               range = c(as.character(start_date), as.character(end_date)),
               rangeslider = list(visible = TRUE, thickness = 0.08),
               showgrid = FALSE, zeroline = FALSE),
  yaxis = list(title = "% change since Feb 2020", ticksuffix = "%", rangemode = "tozero",
               gridcolor = "#E5EAF0", zeroline = TRUE, zerolinecolor = "#6A7789", zerolinewidth = 1.2,
               fixedrange = FALSE),
  legend = list(orientation = "h", x = 0, y = -0.20, xanchor = "left", yanchor = "top",
                font = list(size = 11), itemclick = "toggle", itemdoubleclick = "toggleothers"),
  shapes = list(list(type = "line", x0 = as.character(recovery_date), x1 = as.character(recovery_date),
                     xref = "x", yref = "paper", y0 = 0, y1 = 1,
                     line = list(color = "#68778C", dash = "dot", width = 1))),
  annotations = list(list(x = as.character(recovery_date), y = 0.98, xref = "x", yref = "paper",
                          text = paste0("Total returned: ", month.abb[as.integer(format(recovery_date, "%m"))],
                                        " ", format(recovery_date, "%Y")),
                          showarrow = FALSE, xanchor = "center", yanchor = "top",
                          font = list(size = 11, color = "#596579"))),
  updatemenus = list(
    list(type = "dropdown", x = 0, xanchor = "left", y = 1.22, yanchor = "top", active = 0,
         buttons = list(
           list(label = "Recovery contrasts", method = "restyle", args = list("visible", overview_visibility)),
           list(label = "Goods-producing sectors", method = "restyle", args = list("visible", goods_visibility)),
           list(label = "All sectors", method = "restyle", args = list("visible", all_visibility))
         )),
    list(type = "buttons", direction = "right", x = 0, xanchor = "left", y = 1.10, yanchor = "top", active = 0,
         buttons = list(
           list(label = "% change", method = "update",
                args = list(list(y = pct_values), list("yaxis.title.text" = "% change since Feb 2020",
                                                       "yaxis.ticksuffix" = "%", "yaxis.autorange" = TRUE))),
           list(label = "Job change", method = "update",
                args = list(list(y = job_values), list("yaxis.title.text" = "Job change (thousands)",
                                                       "yaxis.ticksuffix" = "", "yaxis.autorange" = TRUE)))
         ))
  )
)
explorer <- plotly::config(explorer, responsive = TRUE, displaylogo = FALSE,
                           scrollZoom = FALSE,
                           modeBarButtonsToRemove = c("lasso2d", "select2d"),
                           toImageButtonOptions = list(format = "png", filename = "industry_employment"))

# Local standalone HTML contains its JavaScript, so it needs no Plotly account,
# API key, Shiny process, CDN connection, or running R session to view it.
htmlwidgets::saveWidget(explorer, file.path(post_dir, "results/employment_explorer.html"),
                        selfcontained = TRUE, title = "Did every industry recover?")

# A static thumbnail is for the blog listing, not an extra analytical figure.
png(file.path(post_dir, "results/thumbnail.png"), width = 1500, height = 900, res = 150, bg = "white")
par(mar = c(4.2, 5, 3.5, 1), family = "sans", las = 1)
shown <- metadata$series_id %in% contrast_ids
mat <- do.call(cbind, pct_values[shown])
matplot(wide$observation_date, mat, type = "n", axes = FALSE,
        xlab = "", ylab = "% change since February 2020")
abline(h = pretty(range(mat)), col = "#E5EAF0")
abline(h = 0, col = "#68778C")
abline(v = as.numeric(recovery_date), col = "#68778C", lty = 3)
for (i in which(shown)) lines(wide$observation_date, pct_values[[i]], col = metadata$color[i],
                             lwd = if (i == 1) 3 else 2, lty = if (i == 1) 2 else 1)
axis.Date(1, at = as.Date(paste0(2021:2024, "-01-01")), format = "%Y")
axis(2)
title("The total recovered before every sector did", adj = 0, font.main = 2)
legend("bottomright", legend = metadata$sector[shown], col = metadata$color[shown],
       lty = ifelse(which(shown) == 1, 2, 1), lwd = 2, bty = "n", cex = 0.75)
dev.off()
