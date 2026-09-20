# Run once in RStudio. Existing packages are left alone.
packages <- c("rvest", "dplyr", "stringr", "readr", "ggplot2", "scales",
              "rmarkdown", "knitr", "httr2", "jsonlite")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
message("Packages are ready. Now open blog/posts/post2/index.qmd and click Render.")
