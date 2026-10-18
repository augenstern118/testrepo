# Run once in the RStudio Console. No spatial system libraries are needed.
packages <- c("ggplot2", "jsonlite", "knitr", "rmarkdown")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
message("Ready. Open post5/index.qmd and click Render.")
