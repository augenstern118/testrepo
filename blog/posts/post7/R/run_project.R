# Run from the website root or directly inside blog/posts/post7.
# A small local environment avoids overwriting objects in the user's workspace.
post7_result <- new.env(parent = globalenv())
post7_result$post_dir <- if (file.exists("blog/posts/post7/R/01_analyze.R")) {
  "blog/posts/post7"
} else if (file.exists("R/01_analyze.R") && file.exists("data/series.csv")) {
  "."
} else {
  stop("Run from the website root or from blog/posts/post7.")
}
sys.source(file.path(post7_result$post_dir, "R/01_analyze.R"), envir = post7_result)
sys.source(file.path(post7_result$post_dir, "R/02_plot.R"), envir = post7_result)
message("Post 7 complete: CSV results, interactive HTML, thumbnail, and session information saved.")
