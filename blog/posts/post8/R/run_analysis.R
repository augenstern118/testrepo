# Run from the website root or from blog/posts/post8. No downloads occur.
run_post8 <- function() {
  post_dir <- if (file.exists("R/01_simulate.R")) "." else "blog/posts/post8"
  if (!file.exists(file.path(post_dir, "_article-template.qmd"))) {
    stop("Open the website project or the complete post8 folder.")
  }
  old_dir <- getwd()
  on.exit(setwd(old_dir), add = TRUE)
  setwd(post_dir)
  source("R/01_simulate.R", local = TRUE)
  source("R/02_publish.R", local = TRUE)
  result <- run_simulations()
  build_outputs(result)
  message("Post 8 complete: index.qmd, data/ and results/ regenerated.")
  invisible(result)
}
post8_result <- run_post8()
