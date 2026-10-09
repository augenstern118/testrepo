# One replication entry point. Run from the website root or this post2 folder.
# This function restores the original working directory even if analysis fails.
run_project <- function() {
  post_dir <- if (file.exists("R/01_scrape.R")) {
    "."
  } else {
    "blog/posts/post2"
  }
  if (!file.exists(file.path(post_dir, "data/raw/manifest.csv"))) {
    stop("Open the website project or post2 folder, keeping R and data together.")
  }
  old_dir <- getwd()
  on.exit(setwd(old_dir), add = TRUE)
  setwd(post_dir)
  source("R/01_scrape.R", local = TRUE)
  source("R/02_analyze.R", local = TRUE)
  careers <- collect_data("data/raw")
  analysis <- analyze_careers(careers)
  list(sources = sources, careers = careers, analysis = analysis)
}
post2_result <- run_project()
message("Post 2 complete: data/processed/careers.csv and results/ were regenerated.")
