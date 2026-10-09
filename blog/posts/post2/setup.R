# Run once from the website root: source("blog/posts/post2/setup.R")
# Install only missing packages. Rendering never installs packages automatically.
packages <- c("rvest", "dplyr", "stringr", "readr", "ggplot2", "scales",
              "rmarkdown", "knitr")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
message("Ready. Run source('blog/posts/post2/R/run_project.R') or click Render.")
