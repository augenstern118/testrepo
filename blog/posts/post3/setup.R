packages <- c(
  "ipumsr", "dplyr", "tidyr", "ggplot2", "stringr", "forcats",
  "readr", "scales", "haven", "knitr"
)

missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

message("All Blog Post 3 packages are installed.")
