# Run in the RStudio Console from the website root or from this post folder.
# Install only missing packages, once. Rendering does not install packages.
packages <- c("plotly", "htmlwidgets", "knitr", "rmarkdown")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
message("Post 7 packages are ready. Render blog/posts/post7/index.qmd.")
