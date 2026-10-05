# For your Windows RStudio installation; run this once if ggplot2 is missing.
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2", repos = "https://cloud.r-project.org",
                   type = if (.Platform$OS.type == "windows") "binary" else "source")
}
