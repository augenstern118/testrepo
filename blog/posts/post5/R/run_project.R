# Run from the website root or this post5 folder; no download or setwd is required.
run_project <- function() {
  post_dir <- if (file.exists("R/01_prepare.R")) "." else "blog/posts/post5"
  if (!file.exists(file.path(post_dir, "data/raw/manifest.csv"))) {
    stop("Open the website project or the complete post5 folder, keeping R and data together.")
  }
  old_dir <- getwd()
  on.exit(setwd(old_dir), add = TRUE)
  setwd(post_dir)
  dir.create("results", showWarnings = FALSE)
  source("R/01_prepare.R", local = TRUE)
  source("R/02_analyze.R", local = TRUE)
  prepared <- prepare_data()
  analyze_data(prepared)
}
post5_result <- run_project()
message("Post 5 complete: processed data, join audit, maps, chart and tables regenerated.")
